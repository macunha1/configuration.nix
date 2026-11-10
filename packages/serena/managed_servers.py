"""Use module-owned language servers with the pinned Serena/SolidLSP API."""
# SPDX-License-Identifier: MIT

import json
import logging
import os
import re
from pathlib import Path

from solidlsp.dependency_provider import LanguageServerDependencyProvider
from solidlsp.ls import SolidLanguageServer
from solidlsp.ls_config import (
    ExternalLanguageServerId,
    FilenameMatcher,
    LanguageServerRegistry,
)
from solidlsp.lsp_protocol_handler.server import ProcessLaunchInfo


class ManagedDependencyProvider(LanguageServerDependencyProvider):
    def __init__(self, command):
        self.command = command

    def create_launch_command(self):
        return list(self.command)


class ManagedCommand:
    """Keep upstream language behavior while bypassing its dependency installers."""

    managed_command = ()

    def _create_dependency_provider(self):
        return ManagedDependencyProvider(self.managed_command)

    def _get_process_launch_info(self):
        return ProcessLaunchInfo(cmd=list(self.managed_command), cwd=self.repository_root_path)

    @classmethod
    def _setup_runtime_dependencies(cls, *args, **kwargs):
        return cls.managed_command[0]

    @classmethod
    def _setup_runtime_dependency(cls, *args, **kwargs):
        return cls.managed_command[0]

    def install_dependencies(self):
        # All executables belong to the Nix module's runtime closure.
        return None


class StandardLanguageServer(SolidLanguageServer):
    """Standard LSP initialization for servers without an upstream adapter."""

    managed_command = ()
    managed_language_id = ""

    def __init__(self, config, repository_root_path, solidlsp_settings):
        super().__init__(
            config,
            repository_root_path,
            ProcessLaunchInfo(cmd=list(self.managed_command), cwd=repository_root_path),
            self.managed_language_id,
            solidlsp_settings,
        )

    def _create_base_initialize_params(self):
        return {
            "capabilities": {
                "workspace": {"configuration": True, "workspaceFolders": True},
                "textDocument": {
                    "documentSymbol": {"hierarchicalDocumentSymbolSupport": True},
                    "definition": {"linkSupport": True},
                    "hover": {"contentFormat": ["markdown", "plaintext"]},
                    "references": {},
                    "rename": {"prepareSupport": True},
                },
            },
            "initializationOptions": self._custom_settings.get("initializationOptions", {}),
        }

    def _start_server(self):
        def configuration(params):
            settings = self._custom_settings.get("workspace_settings", {})
            return [settings.get(item.get("section"), settings) for item in params.get("items", [])]

        self.server.on_request("workspace/configuration", configuration)
        self.server.on_request("client/registerCapability", lambda params: None)
        self.server.on_notification("textDocument/publishDiagnostics", lambda params: None)
        self.server.on_notification("window/logMessage", lambda params: None)
        self.server.on_notification("$/progress", lambda params: None)
        self.server.start()
        response = self.server.send.initialize(self._create_initialize_params())
        if not response.get("capabilities", {}).get("documentSymbolProvider"):
            logging.getLogger(__name__).warning("Selected server does not advertise document symbols")
        self.server.notify.initialized({})


class DisabledLanguageServer(StandardLanguageServer):
    def __init__(self, config, repository_root_path, solidlsp_settings):
        raise RuntimeError(
            f"Language server '{config.ls_id.get_key()}' is disabled. "
            "Enable its owning language module and languageServer.enable; no fallback server will be installed."
        )


class PatternFilenameMatcher(FilenameMatcher):
    def __init__(self, extensions, pattern):
        super().__init__(*extensions)
        self.pattern = re.compile(pattern)

    def is_relevant_filename(self, filename):
        normalized = filename.replace(os.sep, "/")
        return super().is_relevant_filename(filename) and bool(self.pattern.search(normalized))


def register_servers(servers):
    registry = LanguageServerRegistry.get_instance()
    original = {server.get_key(): server for server in registry.iter_registered_ls_ids()}
    registrations = []
    for key, server in original.items():
        if key not in servers:
            registrations.append(
                ExternalLanguageServerId(key, server.get_source_fn_matcher(), DisabledLanguageServer, priority=0)
            )
    for key, spec in servers.items():
        command = spec["command"]
        if not command or not os.path.isabs(command[0]) or not os.access(command[0], os.X_OK):
            raise ValueError(f"Managed server '{key}' requires an executable absolute command: {command!r}")
        if spec["adapter"] == "generic":
            if not spec["extensions"]:
                raise ValueError(f"Generic server '{key}' requires file extensions")
            base = StandardLanguageServer
            matcher = FilenameMatcher(*spec["extensions"])
            if spec.get("filenamePattern"):
                matcher = PatternFilenameMatcher(spec["extensions"], spec["filenamePattern"])
            priority = 2
        else:
            builtin = original[key]
            base = builtin.get_ls_class()
            matcher = builtin.get_source_fn_matcher()
            priority = builtin.get_priority()
        if spec.get("priority") is not None:
            priority = spec["priority"]
        implementation = type(
            f"Managed_{key}",
            (ManagedCommand, base),
            {"managed_command": tuple(command), "managed_language_id": spec["languageId"]},
        )
        registrations.append(ExternalLanguageServerId(key, matcher, implementation, priority=priority))

    for registration in registrations:
        registry.register(registration, allow_override=True)


def register():
    """SolidLSP's extension hook: register runtime adapters from Nix-rendered metadata."""
    metadata = os.environ.get("SERENA_LANGUAGE_SERVERS")
    if metadata:
        try:
            register_servers(json.loads(Path(metadata).read_text()))
        except Exception as error:
            # Upstream logs and suppresses ordinary extension errors. Managed
            # registration is required, so startup must stop instead of falling back.
            raise SystemExit(f"Cannot configure managed language servers: {error}") from error
