# local/ — dữ liệu trên máy (Drift / SQLite)

7 bảng của `AppDatabase`, schema v9. Đây là **nguồn sự thật** của mọi dữ liệu
sức khoẻ (hard rule 1); Firebase chỉ là bản sao đã mã hoá.

| File | Bảng SQL | Class Drift | Sync? |
| --- | --- | --- | --- |
| `attacks.json` | `attacks` | `Attacks` | có |
| `weather_snapshots.json` | `weather_snapshots` | `WeatherSnapshots` | đi kèm trong payload của attack |
| `medications.json` | `medications` | `Medications` | có |
| `medication_reminders.json` | `medication_reminders` | `MedicationReminders` | có |
| `app_notifications.json` | `app_notifications` | `AppNotifications` | có |
| `export_records.json` | `export_records` | `ExportRecords` | **không** — `filePath` chỉ đúng trên một máy |
| `sync_tombstones.json` | `sync_tombstones` | `SyncTombstones` | là sổ sách của sync, không phải bản ghi |

`all_tables.json` gộp cả 7, sinh ra từ 7 file kia.

## Quy ước

- **Ngày giờ là chuỗi ISO-8601 UTC** cho dễ đọc. Trong SQLite, Drift lưu
  `DateTimeColumn` thành **unix seconds**, nên khi nạp phải parse rồi đổi sang
  epoch giây — mất phần mili giây, đúng như thật.
- **`symptoms` / `triggers` để dạng mảng JSON.** Cột thật là `TEXT` chứa chuỗi
  JSON (`StringListConverter`), mặc định `"[]"`.
- **Enum lưu bằng `.name`**: `location` ∈ left/right/front/back/whole,
  `exertionLevel` ∈ none/light/moderate/severe (null = "chưa từng hỏi"),
  `type` ∈ medicationReminder/pressureAlert, `kind` ∈ json/csv/pdf,
  `collection` ∈ attacks/medications/medication_reminders/notifications.
- **Ba cột sync** (`updatedAt`, `revision`, `syncedRevision`) có ở `attacks`,
  `medications`, `medication_reminders`, `app_notifications`. Dirty là
  `syncedRevision != revision`. `export_records` và `sync_tombstones` không có.
- **`minuteOfDay`** là phút từ nửa đêm giờ máy: 480 = 08:00, 1290 = 21:30.

## Những ca cố tình đưa vào

- `attacks[0]` — đầy đủ, đã đồng bộ (`revision == syncedRevision`).
- `attacks[1]` — **không có weather**: log lúc offline, chờ backfill; đang dirty
  (`syncedRevision: null`) nên chưa có mặt bên `firebase/`.
- `attacks[2]` — không thuốc, `symptoms`/`triggers` rỗng, `exertionLevel: none`
  (một câu trả lời thật, không phải thiếu dữ liệu).
- `attacks[3]` — dòng cũ trước v5/v6: `exertionLevel` và `updatedAt` null,
  `revision: 0`, chưa từng đẩy lên.
- `attacks[4]` — sửa sau khi push: `revision: 5` > `syncedRevision: 4`, nên bản
  trên server là bản cũ hơn.
- `medications[3]` / `medication_reminders[3]` — `createdAt: null`, dòng có
  trước v3 / v8; null nghĩa là "không rõ", không phải ngày chạy migration.
- `app_notifications[2]` — reminder và medication của nó **không còn** trong
  `medications.json`: xoá thuốc thì reminder bị cascade, còn lịch sử "đã được
  nhắc" vẫn phải sống (`medicationId`/`reminderId` không có FK).
- `sync_tombstones` — id ở đây **không** trùng dòng nào trong các file khác, vì
  bản ghi đã bị xoá thật; tombstone chỉ giữ id, không giữ tên hay ghi chú. Bốn
  id này xuất hiện lại bên `firebase/` dưới dạng document `deleted: true`.
