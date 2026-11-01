namespace BigFit.Application.Assistant;

public static class AssistantMessages
{
    public const string Tag = "AI assistant";
    public const string Summary = "Ask BigFit's AI stylist";
    public const string Description =
        "Answers questions in English or Vietnamese using BigFit sizing, policies, and catalogue data.";

    public const string ProviderErrorStatusLog =
        "Configured AI provider returned HTTP {StatusCode}. Details: {Details}";
    public const string ProviderUnreachableLog =
        "Could not reach the configured AI provider.";
    public const string ProviderTimeoutLog =
        "The configured AI provider timed out.";
    public const string ProviderInvalidResponseLog =
        "The configured AI provider returned an invalid response.";

    public static string UnavailableTitle(string language) =>
        language == "en" ? "AI assistant temporarily unavailable" : "Trợ lý AI tạm thời gián đoạn";

    public static string NotConfigured(string language) =>
        language == "en"
            ? "The AI assistant is not configured. Check the provider settings."
            : "Trợ lý AI chưa được cấu hình API key. Vui lòng kiểm tra cấu hình nhà cung cấp.";

    public static string ProviderRequestFailed(string language) =>
        language == "en"
            ? "The AI provider could not complete the request."
            : "Không thể hoàn thành yêu cầu đến nhà cung cấp AI.";

    public static string ProviderEmptyResponse(string language) =>
        language == "en"
            ? "The AI provider returned an empty response."
            : "Nhà cung cấp AI phản hồi rỗng.";

    public static string ProviderUnavailable(string language) =>
        language == "en"
            ? "The AI service is temporarily unavailable. Please try again shortly."
            : "Dịch vụ AI đang tạm thời gián đoạn. Vui lòng thử lại sau ít phút.";

    public static string ProviderTimedOut(string language) =>
        language == "en"
            ? "The request to the AI service timed out."
            : "Yêu cầu đến dịch vụ AI đã hết thời gian chờ.";

    public static string ProviderInvalidResponse(string language) =>
        language == "en"
            ? "The AI service returned an invalid response."
            : "Phản hồi từ dịch vụ AI không hợp lệ.";

    public static string OutOfScopeFallback(string language) =>
        language == "en"
            ? "I’m BigFit’s AI stylist and can help with plus-size fashion, sizing, BigFit products, and store policies. What would you like help finding?"
            : "Dạ, em là AI Stylist chuyên về thời trang Big Size của BigFit ạ. Em chỉ có thể hỗ trợ bạn về tư vấn chọn size, gợi ý phối đồ cho người ngoại cỡ và các sản phẩm, chính sách của BigFit thôi ạ. Bạn có muốn em tư vấn trang phục Big Size nào cho bạn không ạ? 😊";

    public static string SizeGuideFallback(string language) =>
        language == "en"
            ? "Here is a general BigFit size guide:\n\n"
                + "• **Size L**: 65–75 kg (165–172 cm)\n"
                + "• **Size XL**: 75–85 kg (170–178 cm)\n"
                + "• **Size 2XL (XXL)**: 85–95 kg (172–182 cm)\n"
                + "• **Size 3XL**: 95–110 kg (175–188 cm)\n"
                + "• **Size 4XL**: 110–125+ kg (175–190+ cm)\n\n"
                + "For a relaxed fit or a larger waist, consider sizing up. If your measurements are between sizes, choose the larger size."
            : "Dạ chào bạn! Để chọn size BigFit chuẩn nhất cho vóc dáng:\n\n"
                + "• **Size L**: 65kg - 75kg (Cao 1m65 - 1m72)\n"
                + "• **Size XL**: 75kg - 85kg (Cao 1m70 - 1m78)\n"
                + "• **Size 2XL (XXL)**: 85kg - 95kg (Cao 1m72 - 1m82)\n"
                + "• **Size 3XL**: 95kg - 110kg (Cao 1m75 - 1m88)\n"
                + "• **Size 4XL**: 110kg - 125kg+ (Cao 1m75 - 1m90+)\n\n"
                + "💡 *Mẹo*: Nếu bạn thích mặc form thoải mái hoặc có vòng bụng lớn, bạn nên tăng thêm 1 size nhé!";

    public static string PoliciesFallback(string language) =>
        language == "en"
            ? "BigFit store policies:\n\n"
                + "• **Free size exchanges** are available within 7 days of delivery if the item does not fit.\n"
                + "• **Free shipping** applies to orders of 500,000 VND or more.\n"
                + "• **Parcel inspection** is available before payment."
            : "Chính sách bán hàng tại BigFit:\n\n"
                + "• **Đổi size miễn phí**: Trong vòng 7 ngày kể từ khi nhận hàng nếu không vừa vặn.\n"
                + "• **Miễn phí giao hàng**: Cho tất cả đơn hàng từ 500.000 VNĐ.\n"
                + "• **Đồng kiểm**: Bạn được mở bưu phẩm kiểm tra sản phẩm trước khi thanh toán.";

    public static string GeneralFallback(string language) =>
        language == "en"
            ? "Hello! I’m BigFit’s AI stylist. We specialize in plus-size clothing for men and women, from L to 4XL. Share your height and weight and I can suggest a size."
            : "Dạ chào bạn! Em là AI Stylist của BigFit. Cửa hàng chuyên các mẫu thời trang Big Size nam & nữ từ L đến 4XL với chất vải co giãn, thoáng mát. Bạn có thể cung cấp chiều cao và cân nặng để em tư vấn size chuẩn xác nhất nhé!";
}
