# LearnFlow

MVP Flutter cho đề tài **“Mobile App học tiếng Anh và ứng dụng học máy dự đoán lộ trình học”**.

## Những gì đã chạy được

- Mini-game từ vựng rơi và giải mã chữ ghi thời gian phản xạ, đúng/sai sau từng lượt.
- Half-Life Regression dự đoán xác suất nhớ, half-life và thời điểm ôn tiếp theo.
- Softmax ba lớp dự đoán `quá tải / tập trung / nhàm chán` để chọn độ khó.
- Custom Input biến đoạn văn riêng thành bài Nghe, Nói, Đọc hoặc Viết.
- TTS đọc câu tiếng Anh; speech-to-text thu câu nói và chấm độ tương đồng theo từ.
- ML Lab cho phép thay đổi dữ liệu đầu vào và xem quyết định độ khó trực tiếp.
- Trọng số model được nạp từ JSON, sẵn sàng thay bằng kết quả huấn luyện.

## Chạy app

```powershell
flutter pub get
flutter run
```

Microphone và speech recognition đã được khai báo cho Android/iOS. Trên máy ảo không có dịch vụ nhận dạng giọng nói, hãy thử trên thiết bị thật; ba chế độ còn lại vẫn hoạt động.

## Kiểm tra

```powershell
flutter analyze
flutter test
flutter build web
```

Các test tập trung vào seam công khai của HLR, bộ điều chỉnh độ khó, planner và bộ chấm lời nói.

## Huấn luyện model

```powershell
python tool/train_hlr.py D:\data\learning_traces.13m.csv.gz --max-rows 100000
python tool/train_engagement.py data\labelled_sessions.csv
```

Xem [thiết kế ML](docs/ML_DESIGN.md) để biết schema, nguồn dữ liệu, giới hạn và cách đánh giá. Dữ liệu Duolingo không được chép vào repository này; tải từ [duolingo/halflife-regression](https://github.com/duolingo/halflife-regression) theo điều khoản của nguồn.
