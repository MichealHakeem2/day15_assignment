import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/di/service_locator.dart';
import 'package:shopping_app/features/home/presentation/view_model/home_cubit.dart';
import 'package:shopping_app/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    if (!getIt.isRegistered<HomeCubit>()) {
      await configureDependencies();
    }
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
