import 'package:app/shared/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppStrings.language.value = AppLanguage.english;
  });

  test('uses English strings by default', () {
    AppStrings.language.value = AppLanguage.english;

    expect(AppStrings.languageCode, 'EN');
    expect(AppStrings.signIn, 'Sign in');
    expect(AppStrings.brandName, 'BIGFIT');
  });

  test('switches shared and parameterized strings to Vietnamese', () {
    AppStrings.language.value = AppLanguage.vietnamese;

    expect(AppStrings.languageCode, 'VI');
    expect(AppStrings.signIn, 'Đăng nhập');
    expect(AppStrings.productCountLabel(3, 10), '3 / 10 sản phẩm');
    expect(AppStrings.categoryLabel('Bottoms'), 'Quần');
    expect(AppStrings.brandName, 'BIGFIT');
  });
}
