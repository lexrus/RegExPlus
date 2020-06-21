task default: [:sc2tc]

task :sc2tc do
  system "opencc -c s2hk -i RegEx+/zh-Hans.lproj/CheatSheet.plist -o RegEx+/zh-Hant.lproj/CheatSheet.plist"
  system "opencc -c s2hk -i RegEx+/zh-Hans.lproj/Localizable.strings -o RegEx+/zh-Hant.lproj/Localizable.strings"
end