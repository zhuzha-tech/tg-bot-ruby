{ pkgs }: {
  deps = [
    pkgs.ruby_3_1
    pkgs.rubyPackages_3_1.nokogiri
    pkgs.rubyPackages_3_1.racc
    pkgs.rubyPackages_3_1.jaro_winkler
    pkgs.rubyPackages_3_1.webrick
    pkgs.solargraph
    pkgs.rufo
  ];
}