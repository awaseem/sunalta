extension AlarmRecord {
    var soundSelection: AlarmSoundSelection {
        get { AlarmSoundSelection(storedValue: soundName) }
        set { soundName = newValue.storedValue }
    }
}
