import SwiftUI
import CoreLocation
import AVFoundation
import Combine

struct DriverScanRecord: Identifiable, Codable {
    let id: UUID
    let code: String
    let scannedAt: Date

    init(id: UUID = UUID(), code: String, scannedAt: Date = Date()) {
        self.id = id
        self.code = code
        self.scannedAt = scannedAt
    }
}

enum DriverStatsPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "День"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .year: return "Год"
        }
    }
}

@MainActor
final class DriverScanStatsStore: ObservableObject {
    @Published private(set) var records: [DriverScanRecord] = []

    private let defaults = UserDefaults.standard
    private let key = "driver.qrScanRecords"
    private let calendar = Calendar.current

    init() {
        load()
    }

    func recordScan(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        records.insert(DriverScanRecord(code: trimmed), at: 0)
        save()
    }

    func count(for period: DriverStatsPeriod) -> Int {
        records.filter { record in
            isDate(record.scannedAt, inside: period)
        }.count
    }

    func resetToday() {
        records.removeAll { calendar.isDateInToday($0.scannedAt) }
        save()
    }

    private func isDate(_ date: Date, inside period: DriverStatsPeriod) -> Bool {
        switch period {
        case .day:
            return calendar.isDateInToday(date)
        case .week:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        case .year:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DriverScanRecord].self, from: data) else {
            records = []
            return
        }

        records = decoded.sorted { $0.scannedAt > $1.scannedAt }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }
}

struct DriverDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var locationService = LocationService.shared
    @StateObject private var scanStatsStore = DriverScanStatsStore()
    @State private var showScanner = false
    @State private var lastScannedCode: String?
    @State private var selectedStatsPeriod: DriverStatsPeriod = .day

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(alignment: .leading, spacing: 16) {
                        statusCard
                        scanStatsCard
                        scannerCard
                        locationCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 58)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            locationService.startDriverTracking()
        }
        .sheet(isPresented: $showScanner) {
            DriverQRScannerSheet { code in
                lastScannedCode = code
                scanStatsStore.recordScan(code)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Кабинет водителя")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(authVM.currentUserProfile?.fullName ?? "Водитель")
                    .font(.appBody)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button {
                authVM.logout()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.dangerRed)
                    .frame(width: 44, height: 44)
                    .liquidGlassBackground(cornerRadius: 16, style: .clear, tintOpacity: 0.12)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bus.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.accentYellow)
                    .frame(width: 44, height: 44)
                    .background(Color.accentYellow.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Маршрут 43")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Водительский аккаунт активен")
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            Text("Этот экран отделён от пассажирского приложения. Здесь будут инструменты для проверки QR-билетов и передачи позиции автобуса.")
                .font(.appCaption)
                .foregroundColor(.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var scanStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QR-статистика")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Учёт проверенных билетов")
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(scanStatsStore.count(for: selectedStatsPeriod))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.accentTeal)
                    Text("сканов")
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                }
            }

            HStack(spacing: 8) {
                ForEach(DriverStatsPeriod.allCases) { period in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedStatsPeriod = period
                        }
                    } label: {
                        Text(period.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedStatsPeriod == period ? .white : .textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(selectedStatsPeriod == period ? Color.accentTeal : Color.black.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                DriverStatTile(title: "Сегодня", value: scanStatsStore.count(for: .day), icon: "sun.max.fill", color: .accentYellow)
                DriverStatTile(title: "Месяц", value: scanStatsStore.count(for: .month), icon: "calendar", color: .accentGreen)
            }

            if let latest = scanStatsStore.records.first {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.accentGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Последняя проверка")
                            .font(.appCaption)
                            .foregroundColor(.textMuted)
                        Text(latest.scannedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.accentGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button(role: .destructive) {
                scanStatsStore.resetToday()
            } label: {
                Text("Сбросить счётчик дня")
                    .font(.appCaption)
                    .foregroundColor(.dangerRed)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .opacity(scanStatsStore.count(for: .day) == 0 ? 0.45 : 1)
            .disabled(scanStatsStore.count(for: .day) == 0)
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var scannerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Проверка пассажира")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.textPrimary)

            Button {
                showScanner = true
            } label: {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                    Text("Сканировать QR-билет")
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)

            if let lastScannedCode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Последний QR")
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                    Text(lastScannedCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.accentGreen)
                        .lineLimit(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentGreen.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.accentGreen)
                    .frame(width: 42, height: 42)
                    .background(Color.accentGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Геолокация автобуса")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(locationStatusText)
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }
            }

            if let coordinate = locationService.userLocation {
                Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("Для водительского аккаунта приложение запрашивает Always-доступ и поддерживает обновление позиции во время рейса.")
                .font(.appCaption)
                .foregroundColor(.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "Always-доступ включён"
        case .authorizedWhenInUse:
            return "Доступ только при использовании"
        case .notDetermined:
            return "Ожидает разрешение"
        case .denied, .restricted:
            return "Геолокация запрещена"
        @unknown default:
            return "Неизвестный статус"
        }
    }
}

struct DriverStatTile: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 11))

            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.appCaption)
                .foregroundColor(.textMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DriverQRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onScannedCode: (String) -> Void

    var body: some View {
        NavigationStack {
            QRScannerView { code in
                onScannedCode(code)
                dismiss()
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Сканер QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        QRScannerViewController(onCode: onCode)
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let onCode: (String) -> Void
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScan = false

    init(onCode: @escaping (String) -> Void) {
        self.onCode = onCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureScanner()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureScanner() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showFallbackMessage("Камера недоступна на этом устройстве")
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showFallbackMessage("QR-сканер недоступен")
            return
        }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        addScannerOverlay()
    }

    private func addScannerOverlay() {
        let label = UILabel()
        label.text = "Наведите камеру на QR-билет пассажира"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

    private func showFallbackMessage(_ text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else {
            return
        }

        didScan = true
        onCode(value)
    }
}

#Preview {
    DriverDashboardView()
        .environmentObject(AuthViewModel())
}
