# Cấu hình Firebase cho thông báo nhắc streak

> **Trạng thái: bước 1–3 đã xong.** Firebase project của nhóm là
> **`prm393-english-g1-f4f22`**, `android/app/google-services.json` và
> `lib/firebase_options.dart` đã có trong repo. Kéo code về là build được ngay,
> **không cần chạy lại `flutterfire configure`**.
>
> Việc còn lại: **bước 4** (service account key cho backend) — mỗi người tự làm trên
> máy mình vì key không được commit.

App Flutter và backend **bắt buộc dùng chung một Firebase project** — khác project thì token
đăng ký một nơi, server gửi một nơi, thông báo không bao giờ tới.

## Lưu ý khi tạo project (nếu sau này phải tạo lại)

- **Không dùng tài khoản `@fpt.edu.vn`.** Project sẽ bị tạo dưới organization của trường.
- `firebase projects:create` thường **thất bại ở bước `addFirebase` với lỗi 403** nếu tài khoản
  Google chưa từng chấp nhận Điều khoản dịch vụ Firebase. Cách chắc ăn: tạo project bằng tay
  trên [Firebase Console](https://console.firebase.google.com/) trước, rồi mới chạy
  `flutterfire configure --project=<id>`.
- Console hay tự thêm hậu tố vào project id (`prm393-english-g1` → `prm393-english-g1-f4f22`).
  Luôn lấy id thật bằng `firebase projects:list`.

---

## 0. Công cụ

Đã cài sẵn trên máy này:

| Công cụ | Trạng thái |
|---|---|
| `firebase-tools` | đã cài toàn cục (`firebase`) |
| `flutterfire_cli` | đã cài tại `C:\Users\June\AppData\Local\Pub\Cache\bin\flutterfire` |
| `firebase-admin` | đã thêm vào `backend/package.json` |

`flutterfire` chưa nằm trong PATH. Hoặc thêm `C:\Users\June\AppData\Local\Pub\Cache\bin` vào
biến môi trường Path, hoặc gọi bằng đường dẫn đầy đủ trong các lệnh bên dưới.

---

## 1. Đăng nhập Firebase

```powershell
firebase login
```

Lệnh này mở trình duyệt — đăng nhập bằng tài khoản Google sẽ đứng tên chủ project.
Kiểm tra lại:

```powershell
firebase login:list
```

## 2. Tạo project

```powershell
firebase projects:create prm393-english-app --display-name "PRM393 English App"
```

Nếu id đã có người lấy, đổi sang id khác (ví dụ thêm hậu tố nhóm). Xem lại danh sách:

```powershell
firebase projects:list
```

## 3. Nối app Flutter vào project

Chạy trong thư mục `frontend`:

```powershell
cd frontend
C:\Users\June\AppData\Local\Pub\Cache\bin\flutterfire configure --project=prm393-english-app --platforms=android
```

Lệnh này sinh ra:

- `android/app/google-services.json` — Gradle cần file này, thiếu là build lỗi ngay
- `lib/firebase_options.dart` — code hiện không dùng tới (app đọc thẳng cấu hình native),
  giữ lại cũng không sao

Application ID phải là `com.prm.project.prm_frontend` (khớp `android/app/build.gradle.kts`).

> iOS: thêm `,ios` vào `--platforms` nếu nhóm có Apple Developer account để bật APNs.
> Không có thì demo trên Android và ghi rõ trong báo cáo — đúng như phạm vi v1 của tài liệu.

Kiểm tra build:

```powershell
flutter build apk --debug
```

## 4. Cấp credential cho backend

[Firebase Console → Project settings → Service accounts][sa] → **Generate new private key**
→ tải file JSON về.

[sa]: https://console.firebase.google.com/project/prm393-english-g1-f4f22/settings/serviceaccounts/adminsdk

**Không commit file này.** Đây là khoá riêng, ai có nó thì gửi push được dưới danh nghĩa project.

Chọn một trong hai cách, thêm vào `backend/.env`:

```dotenv
# Cách A - trỏ tới file trên đĩa (tiện khi chạy local)
FIREBASE_SERVICE_ACCOUNT_PATH=D:\duong\dan\toi\service-account.json

# Cách B - dán cả nội dung JSON trên 1 dòng (tiện cho Render/Docker)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...","client_email":"..."}
```

Cách B: giữ nguyên `\n` trong `private_key`, backend tự đổi lại thành xuống dòng thật.

Bật luôn bộ lập lịch (mặc định tắt):

```dotenv
NOTIFICATIONS_SCHEDULER_ENABLED=true
```

Khởi động backend, log phải có:

```
[notifications] FCM san sang (project prm393-english-app).
Reminder scheduler started (moi 60s)
```

Nếu thấy `Chua cau hinh FIREBASE_SERVICE_ACCOUNT -> chay che do log` thì backend chỉ ghi log
chứ không gửi thật — kiểm tra lại biến môi trường.

---

## 5. Kiểm thử theo Acceptance Criteria (§10)

Cần **thiết bị Android thật**. Emulator có Google Play Services vẫn nhận được push nhưng hay trễ;
đừng bật chế độ tiết kiệm pin khi demo.

| # | Bước | Kỳ vọng |
|---|---|---|
| 1 | Đăng nhập lần đầu | Hiện hộp thoại xin quyền thông báo. Đồng ý → có bản ghi trong collection `device_tokens` đúng `user_id` |
| 2 | Profile → Nhắc nhở học tập → **Gửi thông báo thử** | Thiết bị nhận push trong vài giây |
| 3 | Bấm thông báo lúc app đang mở / chạy nền / đã tắt hẳn | Cả 3 trường hợp đều vào tab Learn |
| 4 | Bật nhắc, đặt giờ 2 phút sau hiện tại, **không** học gì | Đúng giờ nhận nhắc, nội dung chứa đúng số streak thật |
| 5 | Hoàn thành 1 lesson rồi chờ tới giờ nhắc | Không có thông báo (FR-9) |
| 6 | Tắt switch nhắc nhở | Không nhận nữa; bật lại thì nhận lại |
| 7 | Đăng xuất | Token biến mất khỏi `device_tokens`; đăng nhập tài khoản khác trên cùng máy thì nhận nhắc của tài khoản mới |
| 8 | Từ chối quyền thông báo | App không crash; màn cài đặt hiện thẻ đỏ kèm nút **Mở Cài đặt** |

Thử deep-link tới một bài học cụ thể (Acceptance #4 của tài liệu) bằng cách gửi tay từ
Firebase Console → **Messaging**, hoặc tạm sửa `data` trong
`backend/src/modules/notifications/controller.ts` (`sendTestNotification`) thành:

```ts
{ type: 'streak_reminder', data: { route: 'lesson', lesson_id: '<id-that>' } }
```

`lesson_id` không tồn tại phải rơi về tab Learn kèm SnackBar, không được crash.

---

## Ghi chú

- Giờ nhắc lưu theo **giờ địa phương** của thiết bị; app gửi kèm `tz_offset_minutes`
  (Việt Nam = 420) mỗi lần lưu. Bản ghi tạo trước thay đổi này mặc định `0` (UTC),
  nên user cũ cần vào màn cài đặt lưu lại một lần thì giờ mới đúng.
- Scheduler quét mỗi 60s và cho phép gửi bù trong 5 phút sau giờ đặt, nên thông báo
  đến trong khoảng ±5 phút quanh giờ đặt (NFR-1).
- `google-services.json` không chứa khoá riêng, commit vào repo được. File service account
  thì tuyệt đối không.
