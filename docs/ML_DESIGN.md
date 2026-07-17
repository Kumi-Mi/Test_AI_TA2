# Thiết kế học máy của LearnFlow

LearnFlow dùng hai mô hình riêng vì “sắp quên một từ” và “trạng thái của cả phiên học” là hai mục tiêu khác nhau. Ghép chúng vào một nhãn duy nhất sẽ khiến kết quả khó giải thích và khó đánh giá.

## 1. Mô hình trí nhớ từ vựng

LearnFlow dựa trên Half-Life Regression (HLR) của Settles & Meeder. Với `h` là half-life của một từ và `Δ` là thời gian từ lần gặp gần nhất:

```text
log2(h) = θ · x
p(recall) = 2 ^ (-Δ / h)
```

App xếp từ theo `p(recall)` tăng dần. Từ có xác suất nhớ thấp được đưa vào đầu phiên. Thời điểm ôn tiếp theo là lúc đường cong chạm ngưỡng mục tiêu 75%.

Nguồn gốc: [mã và dữ liệu HLR của Duolingo](https://github.com/duolingo/halflife-regression), [bài báo ACL 2016](https://aclanthology.org/P16-1174/).

### Ánh xạ dữ liệu

| Dữ liệu | Có trong Duolingo | Có trong app | Vai trò |
| --- | --- | --- | --- |
| `p_recall` | Có | Tính từ kết quả | Nhãn huấn luyện |
| `delta` | Có | `hoursSinceLastSeen` | Thời gian trên đường cong quên |
| `history_seen` | Có | `historySeen` | Số lần đã gặp |
| `history_correct` | Có | `historyCorrect` | Độ chính xác lịch sử |
| Thời gian phản xạ | Không | `responseTimeSeconds` | Đặc trưng bổ sung của LearnFlow |
| Số lần gõ/chọn sai | Không tương đương | `errorCount` | Đặc trưng bổ sung của LearnFlow |

Điểm quan trọng: bộ dữ liệu Duolingo không có thời gian phản xạ. Vì vậy script `train_hlr.py` chỉ học `bias`, `seen`, `accuracy` từ dữ liệu công khai. Hai trọng số `responseTime` và `errors` trong bản MVP là cold-start bảo thủ; muốn tuyên bố hai trọng số này “được học”, phải fine-tune bằng log thật của LearnFlow.

### Huấn luyện

```powershell
python tool/train_hlr.py D:\data\learning_traces.13m.csv.gz --max-rows 100000
```

Kết quả ghi thẳng vào `assets/models/memory_model.json`; Flutter nạp tệp này khi khởi động. Bỏ `--max-rows` khi chạy thí nghiệm chính thức. Script chia train/validation theo `user_id`, tránh để cùng một người xuất hiện ở cả hai tập.

## 2. Mô hình trạng thái phiên

Mô hình softmax ba lớp dự đoán:

- `overloaded`: giảm độ khó, chuyển sang mini-game nhẹ và ôn từ sắp quên;
- `focused`: giữ độ khó cân bằng;
- `bored`: tăng thử thách, ví dụ giải mã văn bản hoặc giảm gợi ý.

Đầu vào gồm tỷ lệ thắng, chuỗi thắng/thua, tốc độ so với baseline cá nhân, thời lượng phiên và các đặc trưng tương tác như `fatigue = session × streakLoad`.

### Nhãn không có trong Duolingo

“Quá tải / tập trung / nhàm chán” không tồn tại trong bộ HLR. Cách thu nhãn hợp lệ là hỏi người dùng một câu rất ngắn sau một số phiên, ví dụ chọn một trong ba trạng thái. Không nên tạo nhãn giả từ chính luật dùng để dự đoán vì model chỉ học lại luật đó.

CSV huấn luyện:

```text
user_id,session_id,win_rate,consecutive_wins,consecutive_losses,completion_speed_ratio,session_minutes,label
u01,s01,0.90,6,0,0.82,55,overloaded
```

```powershell
python tool/train_engagement.py data\labelled_sessions.csv
```

Kết quả ghi vào `assets/models/engagement_model.json` và được app nạp trực tiếp. Trước khi có dữ liệu nhãn, tệp hiện tại tự khai báo `source: cold_start_baseline`; app không giả vờ đây là model đã huấn luyện.

## 3. Quyết định lộ trình

```text
Sự kiện từ vựng → HLR → xếp hạng từ có nguy cơ quên
Sự kiện phiên chơi → Softmax → trạng thái + mức độ khó
Hai kết quả → AdaptiveLearningPlanner → mini-game + thứ tự từ
```

Khi dự đoán `overloaded`, planner chọn `gentleReview` và lấy các từ có `p(recall)` thấp nhất. Đây chính là trường hợp “chuỗi thắng cao nhưng chơi quá lâu” được hạ nhịp thay vì tăng khó máy móc.

## 4. Thiết kế thí nghiệm cho đồ án

Nên so sánh ít nhất ba baseline:

1. Lịch cố định hoặc ngẫu nhiên.
2. Spaced repetition không có thời gian phản xạ/lỗi.
3. LearnFlow đầy đủ: HLR mở rộng + điều chỉnh trạng thái phiên.

Đánh giá mô hình trí nhớ bằng MAE của `p_recall`, AUC đúng/sai và tương quan thứ hạng half-life. Đánh giá trạng thái phiên bằng macro-F1 và confusion matrix, không chỉ accuracy vì ba lớp có thể mất cân bằng. Đánh giá sản phẩm bằng retention, tỷ lệ hoàn thành phiên và tự báo cáo tải nhận thức; phải ghi rõ cỡ mẫu thực tế thay vì đặt mục tiêu thành kết quả.

## 5. Riêng tư và giới hạn

- Bản MVP lưu tiến trình từ vựng trong `SharedPreferences` trên thiết bị.
- Speech-to-text phụ thuộc dịch vụ nhận dạng do hệ điều hành cung cấp; hành vi offline phụ thuộc thiết bị.
- Điểm phát âm hiện là độ giống giữa bản chép giọng nói và câu gốc, không phải chấm âm vị/phoneme.
- Muốn nghiên cứu phát âm sâu hơn cần model acoustic/phoneme riêng và bộ dữ liệu có nhãn phát âm.
