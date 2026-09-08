import 'package:flutter_test/flutter_test.dart';
import 'package:frame_crop/main.dart';

void main() {
  testWidgets('FrameCropApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FrameCropApp());
    expect(find.text('Art Studio'), findsOneWidget);
    expect(find.text('Bảo Tàng'), findsOneWidget);
    expect(find.text('TV The Frame'), findsOneWidget);
  });
}
