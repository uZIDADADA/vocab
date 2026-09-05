import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/domain/coach_models.dart';

void main() {
  test('built-in AI provider presets use their compatible endpoints', () {
    const expected = <AiProviderKind, (String, String)>{
      AiProviderKind.gemini: (
        'https://generativelanguage.googleapis.com/v1beta/openai',
        'gemini-3.1-flash-lite',
      ),
      AiProviderKind.deepSeek: (
        'https://api.deepseek.com',
        'deepseek-v4-flash',
      ),
      AiProviderKind.bigModel: (
        'https://open.bigmodel.cn/api/paas/v4',
        'glm-5.2',
      ),
      AiProviderKind.kimi: ('https://api.moonshot.cn/v1', 'kimi-k2.6'),
      AiProviderKind.openAiCompatible: ('https://api.openai.com/v1', ''),
    };

    for (final MapEntry(key: kind, value: values) in expected.entries) {
      final preset = AiProviderConfig.preset(kind);
      expect(preset.kind, kind);
      expect(preset.baseUrl, values.$1);
      expect(preset.model, values.$2);
      expect(AiProviderKindDetails.fromStorage(kind.storageValue), kind);
    }
  });
}
