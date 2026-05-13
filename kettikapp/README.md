# KetTik — iOS App

## 🎨 Цвета
| Элемент | Светлая | Тёмная |
|---------|---------|--------|
| Фон | #FFFFFF | #000000 |
| Акцент | #285CCC | #285CCC |
| Карточки | #F4F5F7 | #1C1C1E |
| Текст | #000000 | #FFFFFF |

## 🚀 Запуск в Xcode

1. **Новый проект**: File → New → Project → App
   - Name: `kettikapp`, Interface: SwiftUI

2. **Удалите**: `ContentView.swift` и `kettikappApp.swift`

3. **Добавьте файлы**: File → Add Files → выберите все папки

4. **Добавьте цвета в Assets.xcassets** (Color Set для каждого):
   - `AppBackground`  → Light: #FFFFFF   / Dark: #000000
   - `CardBackground` → Light: #F4F5F7   / Dark: #1C1C1E
   - `CardBorder`     → Light: #E0E2E8   / Dark: #2C2C2E
   - `TextPrimary`    → Light: #000000   / Dark: #FFFFFF
   - `TextSecondary`  → Light: #606068   / Dark: #98989F
   - `TextMuted`      → Light: #98989F   / Dark: #606068

5. **Логотип автобуса**:
   - В Assets.xcassets создайте Image Set → имя: `BusLogo`
   - Добавьте фото автобуса (IMG_1926)
   - Render As: Template Image (чтобы было белым на синем фоне)

6. **Info.plist** → добавьте:
   `NSLocationWhenInUseUsageDescription` = `Для отображения вашего местоположения`

7. **Run ⌘R**
