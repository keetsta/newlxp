import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

/// Экран отправки/просмотра ответа на блок задания (kind=.task) или КТ (kind=.test).
///
/// Состоит из двух блоков:
///  • Список уже отправленных ответов (текст, файлы, дата, кнопка удаления)
///  • Форма нового ответа: текст-эдитор + прикреплённые файлы (фото/документы) + кнопка «Отправить»
struct AnswerView: View {
    @EnvironmentObject private var store: AppStore
    let topicId: String
    let block: TopicContentBlock

    @State private var draftText: String = ""
    @State private var pendingPhotos: [PhotosPickerItem] = []
    /// Файлы в очереди на отправку: либо локальные данные, либо уже загруженные URL.
    @State private var attachments: [PendingAttachment] = []
    @State private var photoPickerOpen: Bool = false
    @State private var fileImporterOpen: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var deletingAnswerId: String? = nil
    @State private var localError: String? = nil
    /// Подтверждение удаления отправленного ответа: храним id ответа, который
    /// собираемся удалять. nil — диалог не показан.
    @State private var pendingDeleteAnswerId: String? = nil
    /// Открытое во весь экран фото из приложенных к ответу файлов.
    @State private var presentedPhoto: URL? = nil

    private var answers: [StudentTaskAnswer] { store.answersByBlock[block.id] ?? [] }
    private var isLoadingInitial: Bool { store.answersByBlock[block.id] == nil }
    private var canSubmit: Bool {
        !isSubmitting && !attachments.contains(where: { $0.state == .uploading })
            && (!draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if isLoadingInitial {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Загружаем ответы…").font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else if !answers.isEmpty {
                    submittedList
                }
                composer
                if let err = localError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle(block.kind == .test ? "Ответ на КТ" : "Ответ на задание")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $photoPickerOpen, selection: $pendingPhotos, matching: .images)
        .onChange(of: pendingPhotos) { items in
            handlePicked(items)
        }
        .fileImporter(
            isPresented: $fileImporterOpen,
            allowedContentTypes: [.pdf, .image, .plainText, .data],
            allowsMultipleSelection: true
        ) { result in
            handleImported(result)
        }
        .task(id: block.id) {
            if store.answersByBlock[block.id] == nil {
                await store.loadAnswers(topicId: topicId, contentBlockId: block.id)
            }
        }
        .confirmationDialog(
            "Удалить ответ?",
            isPresented: Binding(
                get: { pendingDeleteAnswerId != nil },
                set: { if !$0 { pendingDeleteAnswerId = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeleteAnswerId
        ) { answerId in
            Button("Удалить", role: .destructive) {
                pendingDeleteAnswerId = nil
                Task {
                    deletingAnswerId = answerId
                    defer { Task { @MainActor in deletingAnswerId = nil } }
                    _ = await store.deleteAnswer(
                        answerId: answerId,
                        topicId: topicId,
                        contentBlockId: block.id
                    )
                }
            }
            Button("Отмена", role: .cancel) {
                pendingDeleteAnswerId = nil
            }
        } message: { _ in
            Text("Восстановить отправленный ответ нельзя.")
        }
        .fullScreenCover(item: Binding<IdentifiableURL?>(
            get: { presentedPhoto.map { IdentifiableURL(url: $0) } },
            set: { presentedPhoto = $0?.url }
        )) { photo in
            PhotoViewerView(url: photo.url) {
                presentedPhoto = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        GlassCard(padding: 18, corner: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(block.kind == .test ? "Контрольная точка".uppercased() : "Задание".uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(block.kind == .test ? Color.blue : Color.orange)
                    .tracking(0.6)
                Text(block.name)
                    .font(.headline)
                if let m = block.maxScore, m > 0 {
                    Text("До \(Int(m.rounded())) баллов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if let dl = block.deadline {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text(deadlineLine(dl))
                    }
                    .font(.caption)
                    .foregroundStyle(dl < Date() ? .red : .secondary)
                }
            }
        }
    }

    // MARK: - Submitted answers

    private var submittedList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Отправленные ответы", trailing: "\(answers.count)")
            VStack(spacing: 10) {
                ForEach(answers) { a in
                    submittedRow(a)
                }
            }
        }
    }

    private func submittedRow(_ a: StudentTaskAnswer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formatSubmitted(a.createdAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if a.isEdited {
                    Text("· изменено").font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    pendingDeleteAnswerId = a.id
                } label: {
                    if deletingAnswerId == a.id {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
                .disabled(deletingAnswerId == a.id)
            }
            // Сначала пытаемся показать rich-text `content` (Editor.js / HTML),
            // который ставит веб-клиент ITHub — там бывают inline-картинки и
            // форматирование. Если его нет или это пустой массив блоков —
            // фолбэк на plain `text`.
            answerContent(a)
            if !a.filesUrls.isEmpty {
                let images = a.filesUrls.filter { isImageURL($0) }
                let others = a.filesUrls.filter { !isImageURL($0) }
                if !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images, id: \.self) { url in
                                if let u = URL(string: url) {
                                    Button {
                                        presentedPhoto = u
                                    } label: {
                                        RemoteImage(url: u)
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                if !others.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(others, id: \.self) { url in
                            if let u = URL(string: url) {
                                Link(destination: u) {
                                    attachmentRow(name: fileName(from: url), trailing: "arrow.up.right")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lxpGlass(cornerRadius: 18)
    }

    @ViewBuilder
    private func answerContent(_ a: StudentTaskAnswer) -> some View {
        if let raw = a.content, !raw.isEmpty {
            if let blocks = EditorJSParser.parse(raw), !blocks.isEmpty {
                // Передаём колбэк — встроенные картинки из веб-редактора
                // ITHub станут тапабельными и откроют PhotoViewerView.
                EditorContentView(blocks: blocks) { url in
                    presentedPhoto = url
                }
            } else {
                Text(InlineHTML.attributed(raw))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if !a.text.isEmpty {
            Text(a.text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: answers.isEmpty ? "Ваш ответ" : "Добавить ещё ответ")
            VStack(alignment: .leading, spacing: 12) {
                textEditor
                if !attachments.isEmpty {
                    if hasImageAttachments {
                        attachmentPreviews
                    }
                    VStack(spacing: 6) {
                        ForEach(attachments) { att in
                            attachmentEditableRow(att)
                        }
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        photoPickerOpen = true
                    } label: {
                        Label("Фото", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .lxpGlassCapsule()
                    }
                    .buttonStyle(.plain)
                    Button {
                        fileImporterOpen = true
                    } label: {
                        Label("Файл", systemImage: "paperclip")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .lxpGlassCapsule()
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                submitButton
            }
            .padding(14)
            .lxpGlass(cornerRadius: 20)
        }
    }

    private var hasImageAttachments: Bool {
        attachments.contains { isImageExtension($0.fileExtension) }
    }

    private var attachmentPreviews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { att in
                    if isImageExtension(att.fileExtension), let img = UIImage(data: att.data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            if att.state == .uploading {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.35))
                                    .frame(width: 96, height: 96)
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 96, height: 96)
                            }
                            Button {
                                attachments.removeAll { $0.id == att.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func isImageExtension(_ ext: String) -> Bool {
        let e = ext.lowercased()
        return ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "bmp"].contains(e)
    }

    private func isImageURL(_ url: String) -> Bool {
        let path = URL(string: url)?.path ?? url
        return isImageExtension((path as NSString).pathExtension)
    }

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            if draftText.isEmpty {
                Text(block.kind == .test ? "Опишите ход решения, прикрепите файлы…" : "Текст ответа")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: $draftText)
                .font(.subheadline)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 6) {
                if isSubmitting { ProgressView().controlSize(.small).tint(.white) }
                Text(isSubmitting ? "Отправляем" : "Отправить")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Image(systemName: "paperplane.fill")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func attachmentRow(name: String, trailing: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "paperclip")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Image(systemName: trailing)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.primary.opacity(0.05))
        )
    }

    private func attachmentEditableRow(_ att: PendingAttachment) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconFor(att))
                .font(.caption)
                .foregroundStyle(stateTint(att.state))
            Text(att.fileName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            switch att.state {
            case .ready:
                Text(formatBytes(att.data.count))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
                Button {
                    attachments.removeAll { $0.id == att.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            case .uploading:
                ProgressView().controlSize(.small)
            case .uploaded:
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            case .failed:
                Text("ошибка").font(.caption2).foregroundStyle(.red)
                Button {
                    attachments.removeAll { $0.id == att.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.primary.opacity(0.05))
        )
    }

    private func stateTint(_ s: PendingAttachment.State) -> Color {
        switch s {
        case .ready: .secondary
        case .uploading: .blue
        case .uploaded: .green
        case .failed: .red
        }
    }

    private func iconFor(_ att: PendingAttachment) -> String {
        let lower = att.fileName.lowercased()
        if lower.hasSuffix(".pdf") { return "doc.richtext" }
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".heic") {
            return "photo"
        }
        if lower.hasSuffix(".doc") || lower.hasSuffix(".docx") || lower.hasSuffix(".odt") { return "doc.text" }
        return "paperclip"
    }

    // MARK: - Picker / importer handlers

    private func handlePicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let ext: String
                    let name: String
                    if let suggested = item.supportedContentTypes.first {
                        let preferred = suggested.preferredFilenameExtension ?? "jpg"
                        ext = preferred
                        name = "photo-\(Int(Date().timeIntervalSince1970)).\(preferred)"
                    } else {
                        ext = "jpg"
                        name = "photo-\(Int(Date().timeIntervalSince1970)).jpg"
                    }
                    await MainActor.run {
                        attachments.append(PendingAttachment(
                            fileName: name,
                            fileExtension: ext.uppercased(),
                            mimeType: mimeFromExtension(ext),
                            data: data
                        ))
                    }
                }
            }
            await MainActor.run { pendingPhotos = [] }
        }
    }

    private func handleImported(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let didStart = url.startAccessingSecurityScopedResource()
                defer { if didStart { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    let ext = url.pathExtension.isEmpty ? "bin" : url.pathExtension
                    attachments.append(PendingAttachment(
                        fileName: url.lastPathComponent,
                        fileExtension: ext.uppercased(),
                        mimeType: mimeFromExtension(ext),
                        data: data
                    ))
                }
            }
        case .failure(let err):
            localError = err.localizedDescription
        }
    }

    // MARK: - Submit

    private func submit() async {
        localError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        // Сначала аплоадим все локальные файлы и собираем URL'ы.
        var uploadedUrls: [String] = []
        for index in attachments.indices {
            if let url = attachments[index].uploadedUrl {
                uploadedUrls.append(url)
                continue
            }
            attachments[index].state = .uploading
            do {
                let url = try await UploadRepository.uploadFile(
                    data: attachments[index].data,
                    fileName: attachments[index].fileName,
                    fileExtension: attachments[index].fileExtension,
                    mimeType: attachments[index].mimeType
                )
                attachments[index].uploadedUrl = url
                attachments[index].state = .uploaded
                uploadedUrls.append(url)
            } catch {
                attachments[index].state = .failed
                localError = "Не удалось загрузить файл «\(attachments[index].fileName)»: \(error.localizedDescription)"
                return
            }
        }

        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let ok = await store.submitAnswer(
            topicId: topicId,
            contentBlockId: block.id,
            text: text,
            filesUrl: uploadedUrls
        )
        if ok {
            draftText = ""
            attachments.removeAll()
        } else {
            localError = store.lastError ?? "Не удалось отправить ответ"
        }
    }

    // MARK: - Helpers

    private func deadlineLine(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, HH:mm"
        return "Срок: " + f.string(from: d)
    }

    private func formatSubmitted(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, HH:mm"
        return f.string(from: d)
    }

    private func fileName(from url: String) -> String {
        URL(string: url)?.lastPathComponent ?? url
    }

    private func formatBytes(_ count: Int) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: Int64(count))
    }

    private func mimeFromExtension(_ ext: String) -> String {
        if let utType = UTType(filenameExtension: ext.lowercased()),
           let mime = utType.preferredMIMEType {
            return mime
        }
        return "application/octet-stream"
    }
}

/// Локально хранимый файл, который ещё не отправлен на сервер. После аплоада
/// `uploadedUrl` заполняется — это то, что улетает в `CreateAnswer.filesUrl`.
struct PendingAttachment: Identifiable {
    enum State { case ready, uploading, uploaded, failed }
    let id = UUID()
    let fileName: String
    let fileExtension: String
    let mimeType: String
    let data: Data
    var uploadedUrl: String? = nil
    var state: State = .ready
}

/// Обёртка для презентации фотографии через `fullScreenCover(item:)` —
/// `URL` нет `Identifiable` по умолчанию.
private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Полноэкранный просмотр фотографии с pinch-to-zoom и сохранением в Фото.
/// Загружаем тем же `RemoteImageLoader`, что и thumbnail — он кэширует
/// расшифрованный `UIImage`, чтобы не качать дважды.
struct PhotoViewerView: View {
    let url: URL
    let onClose: () -> Void

    @State private var image: UIImage?
    @State private var failed: Bool = false
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var statusMessage: String?
    @State private var statusIsError: Bool = false
    @State private var showShareSheet: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1, min(6, lastScale * value))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        scale = 1
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            if scale > 1 {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }
            } else if failed {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    Text("Не удалось загрузить изображение")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Link("Открыть в браузере", destination: url)
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }

            VStack {
                topBar
                Spacer()
                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(statusIsError ? Color.red.opacity(0.85) : Color.black.opacity(0.6))
                        )
                        .foregroundStyle(.white)
                        .padding(.bottom, 28)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .task(id: url) { await loadImage() }
        .sheet(isPresented: $showShareSheet) {
            if let image {
                ShareSheet(items: [image])
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .buttonStyle(.plain)

            Spacer()

            if image != nil {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.black.opacity(0.5)))
                }
                .buttonStyle(.plain)

                Button {
                    saveToPhotos()
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func loadImage() async {
        if let cached = RemoteImageLoader.shared.image(for: url) {
            self.image = cached
            return
        }
        if let loaded = await RemoteImageLoader.shared.load(url) {
            self.image = loaded
        } else {
            self.failed = true
        }
    }

    private func saveToPhotos() {
        guard let image else { return }
        // PHPhotoLibrary.requestAuthorization сам показывает системный prompt
        // при первом обращении. UIImageWriteToSavedPhotosAlbum использует те
        // же права (NSPhotoLibraryAddUsageDescription).
        PhotoSaveHelper.save(image: image) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    showStatus("Сохранено в Фото", isError: false)
                case .failure(let err):
                    showStatus("Не удалось сохранить: \(err.localizedDescription)", isError: true)
                }
            }
        }
    }

    private func showStatus(_ text: String, isError: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            statusMessage = text
            statusIsError = isError
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                statusMessage = nil
            }
        }
    }
}

/// Обёртка над `UIImageWriteToSavedPhotosAlbum` — Apple использует selector-based
/// completion, а нам удобнее замыкание.
private final class PhotoSaveHelper: NSObject {
    private let completion: (Result<Void, Error>) -> Void
    private static var inflight: [PhotoSaveHelper] = []

    private init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }

    static func save(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        let helper = PhotoSaveHelper(completion: completion)
        inflight.append(helper)
        UIImageWriteToSavedPhotosAlbum(
            image,
            helper,
            #selector(PhotoSaveHelper.finished(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc private func finished(_ image: UIImage,
                                didFinishSavingWithError error: Error?,
                                contextInfo: UnsafeRawPointer) {
        if let error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
        Self.inflight.removeAll { $0 === self }
    }
}

/// Стандартный `UIActivityViewController` через UIViewControllerRepresentable —
/// нативный share-sheet с «Сохранить изображение», AirDrop и прочим.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
