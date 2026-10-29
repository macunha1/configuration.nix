{ ... }:

{
  browserSearchEngines = {
    DuckDuckGo = {
      keyword = "duckduckgo.com";
      searchURL = "https://duckduckgo.com/?q={searchTerms}";
    };

    Google = {
      keyword = "google.com";
      searchURL = "https://www.google.com/search?q={searchTerms}";
    };
  };
}
