/// What to do with this device's local data after deleting the cloud account
/// (HU-07, paso 2). Neither option is a default — the UI must force an
/// explicit pick, never a preselected one (no dark pattern).
enum LocalDataChoice { keep, delete }
