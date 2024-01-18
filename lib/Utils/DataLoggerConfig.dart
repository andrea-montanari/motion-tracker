class DataLoggerConfig {

  static String getDataLoggerConfig(String resource) {
    String config =
      "{"
        "\"config\":{"
          "\"dataEntries\":{"
            "\"dataEntry\":["
              "{"
                "\"path\":\"$resource\""
              "}"
            "]"
          "}"
        "}"
      "}";
    return config;
  }
}