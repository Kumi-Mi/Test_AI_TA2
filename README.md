# LearnFlow

Ứng dụng Flutter cho đề tài **“Mobile App học tiếng Anh và ứng dụng học máy dự đoán lộ trình học”**.

## Trạng thái hiện tại

- Mini-game bắt từ rơi và giải mã chữ dùng kho **1.718 từ/cụm từ Anh–Việt**, không còn giới hạn ở 8 từ mẫu.
- Pipeline quét **5.014.791 trace học tiếng Anh** trong toàn bộ **12.854.226 dòng** của bộ Duolingo HLR; 4.689.398 trace ghép được nội dung hợp lệ cho mini-game và đủ 12 cột CSV đều có vai trò được tài liệu hóa.
- Half-Life Regression (HLR) được huấn luyện trên toàn bộ dữ liệu: 11.530.392 dòng train, 1.323.834 dòng validation, MAE recall 0,11337.
- HLR dự đoán xác suất nhớ, half-life và thời điểm ôn; planner ưu tiên từ có nguy cơ quên.
- Bộ phân loại softmax dự đoán `quá tải / tập trung / nhàm chán` để chọn nhịp chơi và độ khó.
- Custom Input biến văn bản riêng thành bài Nghe, Nói, Đọc hoặc Viết; TTS đọc câu và speech-to-text chấm độ giống theo từ.
- Tiến trình cá nhân được ghép lên catalog mới và lưu cục bộ bằng `SharedPreferences`.

## Chạy app

```powershell
flutter pub get
flutter run
```

Sau khi thay asset dữ liệu, hãy dừng app và chạy lại hoàn toàn thay vì chỉ hot reload. Microphone và speech recognition đã được khai báo cho Android/iOS; nên thử chức năng Nói trên thiết bị thật.

## Kiểm tra và build

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

APK debug được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

## Tái tạo dữ liệu từ CSV

CSV gốc dung lượng lớn được đặt trong `data_csv/` và bị Git bỏ qua. App không đọc file `.csv.gz` trên điện thoại; app đọc hai asset đã xử lý sẵn:

- `assets/models/memory_model.json`: trọng số HLR;
- `assets/data/duolingo_english_vocabulary.json`: catalog từ, nghĩa và prior thống kê.

Dùng Python đã đi kèm Codex trên máy hiện tại:

```powershell
$py = 'C:\Users\Komi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'

& $py .\tool\train_hlr.py `
  .\data_csv\settles.acl16.learning_traces.13m.csv.gz

& $py .\tool\build_vocabulary_catalog.py `
  .\data_csv\settles.acl16.learning_traces.13m.csv.gz `
  --dictionary-dir .\data_csv\engvie_jar\dictionary
```

Nghĩa tiếng Việt lấy từ Free Vietnamese Dictionary Project (FVDP), bản đóng gói DictionaryForMIDs English–Vietnamese 109k. Tải từ [trang từ điển DictionaryForMIDs](https://dictionarymid.sourceforge.net/dictionaries/dictsVietnameese.html), giải nén JAR và đặt các file `directoryEng*.csv` dưới thư mục truyền cho `--dictionary-dir`.

Xem [thiết kế ML](docs/ML_DESIGN.md) để biết ánh xạ từng cột, giới hạn mô hình và cách đánh giá. Xem [thông báo bên thứ ba](THIRD_PARTY_NOTICES.md) để biết nguồn và giấy phép dữ liệu.

## Giới hạn cần nói rõ khi bảo vệ

Bộ Duolingo không có thời gian phản xạ, số lỗi gõ của LearnFlow, cũng không có nhãn `quá tải / tập trung / nhàm chán`. Vì vậy các trọng số tương ứng vẫn là cold-start và sẽ được fine-tune khi thu đủ log/nhãn từ người dùng thật. Điểm Nói hiện đo độ giống bản chép lời, chưa phải chấm âm vị.
