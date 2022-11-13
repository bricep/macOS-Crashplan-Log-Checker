sudo launchctl unload /Library/LaunchDaemons/com.crashplan.engine.plist
sleep 20s
sudo launchctl load /Library/LaunchDaemons/com.crashplan.engine.plist