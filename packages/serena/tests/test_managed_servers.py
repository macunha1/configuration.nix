"""Run with the Python environment of the pinned Serena source."""

import importlib.metadata
import json
import os
import select
import subprocess
import sys
from pathlib import Path

import pytest
from solidlsp.ls import SolidLanguageServer
from solidlsp.ls_config import LanguageServerConfig, LanguageServerRegistry
from solidlsp.settings import SolidLSPSettings
from solidlsp import managed_servers as managed
from serena.config.serena_config import SerenaConfig


@pytest.fixture(autouse=True)
def isolated_registry():
    original = LanguageServerRegistry._instance
    LanguageServerRegistry._instance = None
    yield
    LanguageServerRegistry._instance = original


def python_server(command):
    return {
        "adapter": "generic",
        "command": command,
        "languageId": "python",
        "extensions": [".py", ".pyi"],
        "settings": {},
    }


def test_disabled_servers_cannot_fall_back_to_another_implementation(tmp_path):
    managed.register_servers({"python": python_server([sys.executable])})
    registry = LanguageServerRegistry.get_instance()
    disabled = registry.resolve("python_basedpyright")
    assert disabled.get_priority() == 0
    with pytest.raises(RuntimeError, match="no fallback server"):
        disabled.get_ls_class()(LanguageServerConfig(disabled), str(tmp_path), None)


def test_builtin_adapter_preserves_language_behavior_and_exact_command(tmp_path):
    from solidlsp.language_servers.gopls import Gopls

    managed.register_servers({"go": {"adapter": "builtin", "command": [sys.executable], "languageId": "go"}})
    selected = LanguageServerRegistry.get_instance().resolve("go")
    assert issubclass(selected.get_ls_class(), Gopls)
    settings = SolidLSPSettings(solidlsp_dir=str(tmp_path / "lsp"), project_data_path=str(tmp_path / "project"))
    server = SolidLanguageServer.create(LanguageServerConfig(selected), str(tmp_path), solidlsp_settings=settings)
    assert server._get_process_launch_info().cmd == [sys.executable]
    assert server._dependency_provider is None


@pytest.mark.parametrize(
    "key", ["go", "rust", "cpp_ccls", "lua", "elixir", "nix", "terraform", "ansible", "bash", "yaml"]
)
def test_builtin_constructors_keep_managed_commands_without_installers(tmp_path, key):
    managed.register_servers({key: {"adapter": "builtin", "command": [sys.executable], "languageId": key}})
    selected = LanguageServerRegistry.get_instance().resolve(key)
    settings = SolidLSPSettings(solidlsp_dir=str(tmp_path / "lsp"), project_data_path=str(tmp_path / "project"))
    server = SolidLanguageServer.create(LanguageServerConfig(selected), str(tmp_path), solidlsp_settings=settings)
    server.install_dependencies()
    assert server._get_process_launch_info().cmd == [sys.executable]


def test_helm_matches_templates_without_claiming_plain_kubernetes_yaml():
    matcher = managed.PatternFilenameMatcher([".tpl", ".yaml", ".yml"], r"(^|/)templates/.*\.(yaml|yml)$|\.tpl$")
    assert matcher.is_relevant_filename("/repo/charts/app/templates/deployment.yaml")
    assert matcher.is_relevant_filename("/repo/charts/app/templates/_helpers.tpl")
    assert not matcher.is_relevant_filename("/repo/kubernetes/deployment.yaml")
    assert not matcher.is_relevant_filename("/repo/charts/app/values.yaml")


def test_missing_managed_executable_fails_without_downloading():
    with pytest.raises(ValueError, match="executable absolute command"):
        managed.register_servers({"python": python_server(["/nonexistent/zuban", "server"])})


def test_missing_explicit_configuration_is_not_created(tmp_path, monkeypatch):
    configuration = tmp_path / "missing.yml"
    monkeypatch.setenv("SERENA_CONFIG_FILE", str(configuration))
    with pytest.raises(FileNotFoundError):
        SerenaConfig.from_config_file()
    assert not configuration.exists()


def test_default_mutable_configuration_still_persists(tmp_path, monkeypatch):
    configuration = tmp_path / "serena.yml"
    monkeypatch.delenv("SERENA_CONFIG_FILE", raising=False)
    monkeypatch.setattr(SerenaConfig, "_determine_config_file_path", classmethod(lambda cls: str(configuration)))
    settings = SerenaConfig.from_config_file()
    settings.save_web_dashboard_open_on_launch(False)
    assert SerenaConfig.from_config_file().web_dashboard_open_on_launch is False
    assert configuration.stat().st_mode & 0o777 == 0o600


def test_invalid_manifest_does_not_partially_change_the_registry():
    registry = LanguageServerRegistry.get_instance()
    original = {server.get_key(): server.get_ls_class() for server in registry.iter_registered_ls_ids()}
    with pytest.raises(ValueError, match="executable absolute command"):
        managed.register_servers({
            "python": python_server([sys.executable]),
            "go": {"adapter": "builtin", "command": ["/nonexistent/gopls"], "languageId": "go"},
        })
    assert {server.get_key(): server.get_ls_class() for server in registry.iter_registered_ls_ids()} == original


def test_required_registration_failure_escapes_upstream_discovery(tmp_path, monkeypatch):
    registry = LanguageServerRegistry.get_instance()
    metadata = tmp_path / "servers.json"
    metadata.write_text(json.dumps({"go": {
        "adapter": "builtin", "command": ["/nonexistent/gopls"], "languageId": "go",
    }}))
    monkeypatch.setenv("SERENA_LANGUAGE_SERVERS", str(metadata))

    class Registration:
        name = "managed-test"
        dist = None

        def load(self):
            return managed.register

    monkeypatch.setattr(importlib.metadata, "entry_points", lambda **kwargs: [Registration()])
    with pytest.raises(SystemExit, match="Cannot configure managed language servers"):
        registry._discover_language_server_registrations_from_entry_points()


def test_packaged_cli_stops_on_an_invalid_managed_command(tmp_path):
    metadata = tmp_path / "servers.json"
    metadata.write_text(json.dumps({"go": {
        "adapter": "builtin", "command": ["/nonexistent/gopls"], "languageId": "go",
    }}))
    configuration = tmp_path / "managed.yml"
    configuration.write_text(json.dumps({
        "projects": [], "agent_interface": "REPL", "web_dashboard": False,
        "gui_log_window": False, "excluded_apis": ["mem", "shell", "fs"],
    }))
    (tmp_path / "main.go").write_text("package main\n")
    result = subprocess.run(
        [os.environ["SERENA_BIN"], "start-mcp-server", "--project-from-cwd"],
        cwd=tmp_path, input="", text=True, capture_output=True, timeout=30,
        env=os.environ | {
            "SERENA_HOME": str(tmp_path / "runtime"),
            "SERENA_CONFIG_FILE": str(configuration),
            "SERENA_LANGUAGE_SERVERS": str(metadata),
        },
    )
    assert result.returncode != 0
    assert "Cannot configure managed language servers" in result.stderr


def test_managed_mcp_starts_without_rewriting_a_global_config(tmp_path):
    metadata = tmp_path / "servers.json"
    metadata.write_text(json.dumps({"python": python_server([sys.executable])}))
    configuration = tmp_path / "managed.yml"
    configuration.write_text(json.dumps({
        "projects": [], "agent_interface": "REPL", "web_dashboard": False,
        "gui_log_window": False, "excluded_apis": ["mem", "shell", "fs"],
        "ls_specific_settings": {},
    }))
    configuration.chmod(0o444)
    original = configuration.read_bytes()
    context = tmp_path / "managed.context.yml"
    context.write_text('description: Test context\nprompt: Use symbol queries.\nexcluded_tools: []\n')
    runtime_home = tmp_path / "runtime"
    environment = os.environ | {
        "SERENA_HOME": str(runtime_home), "SERENA_CONFIG_FILE": str(configuration),
        "SERENA_LANGUAGE_SERVERS": str(metadata),
    }
    command = [os.environ.get("SERENA_BIN", str(Path(sys.executable).parent / "serena")), "start-mcp-server",
               "--project-from-cwd", "--context", str(context)]
    with (tmp_path / "server.log").open("w+") as log:
        process = subprocess.Popen(
            command, cwd=tmp_path,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log, text=True, env=environment,
        )
        try:
            request = {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
                "protocolVersion": "2025-03-26", "capabilities": {},
                "clientInfo": {"name": "integration-test", "version": "1"},
            }}
            process.stdin.write(json.dumps(request) + "\n")
            process.stdin.flush()
            ready = select.select([process.stdout], [], [], 30)[0]
            if not ready:
                log.seek(0)
                pytest.fail("MCP initialization timed out: " + log.read()[-1500:])
            line = process.stdout.readline()
            if not line:
                log.seek(0)
                pytest.fail("MCP process exited: " + log.read()[-1500:])
            response = json.loads(line)
            assert "result" in response, response
            assert response["result"]["serverInfo"]["name"] == "Serena"
            assert not (runtime_home / "serena_config.yml").exists()
            assert configuration.read_bytes() == original
            assert configuration.stat().st_mode & 0o777 == 0o444
        finally:
            process.terminate()
            process.communicate(timeout=10)


@pytest.mark.skipif(not os.environ.get("ZUBAN_BIN"), reason="Set ZUBAN_BIN to run the real selected server")
def test_zuban_symbols_references_and_definitions(tmp_path):
    (tmp_path / "sample.py").write_text("def greet(name: str) -> str:\n    return name\n\ngreet('world')\n")
    managed.register_servers({"python": python_server([os.environ["ZUBAN_BIN"], "server"])})
    selected = LanguageServerRegistry.get_instance().resolve("python")
    settings = SolidLSPSettings(solidlsp_dir=str(tmp_path / "lsp"), project_data_path=str(tmp_path / "project"))
    server = SolidLanguageServer.create(
        LanguageServerConfig(selected), str(tmp_path), solidlsp_settings=settings, timeout=15
    )
    with server.start_server_context():
        symbols = server.request_document_symbols("sample.py")
        assert "greet" in {symbol["name"] for symbol in symbols.iter_symbols()}
        assert server.request_definition("sample.py", 3, 1)
        assert server.request_references("sample.py", 0, 5)
        edit = server.request_rename_symbol_edit("sample.py", 0, 5, "welcome")
        assert edit and "welcome" in json.dumps(edit)
