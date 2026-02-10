
import '../domain/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications();
}

class NotificationRepositoryMock implements NotificationRepository {
  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    return [
      NotificationModel(
        id: '1',
        title: 'ระบบเริ่มต้นแล้ว',
        message: 'ระบบกำลังตรวจจับท่าทางแบบ Real-time',
        type: NotificationType.success,
        date: DateTime.now(),
      ),
      NotificationModel(
        id: '2',
        title: 'เตือนการนั่งนาน',
        message: 'คุณนั่งทำงานเกิน 2 ชั่วโมงแล้ว ควรลุกยืดเส้น',
        type: NotificationType.warning,
        date: DateTime.now(),
      ),
      NotificationModel(
        id: '3',
        title: 'ตรวจพบความเสี่ยง',
        message: 'พบพฤติกรรมล้ม กรุณาตรวจสอบทันที',
        type: NotificationType.danger,
        date: DateTime.now(),
      ),
    ];
  }
}
