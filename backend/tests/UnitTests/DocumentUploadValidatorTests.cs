using EasyAgree.Application.Documents;

namespace UnitTests;

public sealed class DocumentUploadValidatorTests
{
    [Fact]
    public void Accepts_jpeg_when_declared_type_matches_signature()
    {
        var result = DocumentUploadValidator.Validate([new UploadedFile("car.jpg", "image/jpeg", [0xFF, 0xD8, 0xFF, 0x00])]);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Rejects_declared_type_that_does_not_match_file_bytes()
    {
        var result = DocumentUploadValidator.Validate([new UploadedFile("car.png", "image/png", [0xFF, 0xD8, 0xFF, 0x00])]);

        Assert.False(result.IsValid);
        Assert.Equal("DOCUMENT_CONTENT_TYPE_MISMATCH", result.ErrorCode);
        Assert.Equal(0, result.FileIndex);
    }

    [Fact]
    public void Rejects_unknown_content_even_when_name_looks_like_an_image()
    {
        var result = DocumentUploadValidator.Validate([new UploadedFile("../../payload.jpg", "image/jpeg", "<script>bad</script>"u8.ToArray())]);

        Assert.False(result.IsValid);
        Assert.Equal("UNSUPPORTED_DOCUMENT_TYPE", result.ErrorCode);
    }

    [Fact]
    public void Rejects_image_bytes_when_file_extension_is_not_an_image_extension()
    {
        var result = DocumentUploadValidator.Validate([new UploadedFile("car.exe", "image/jpeg", [0xFF, 0xD8, 0xFF, 0x00])]);

        Assert.False(result.IsValid);
        Assert.Equal("DOCUMENT_EXTENSION_MISMATCH", result.ErrorCode);
    }

    [Fact]
    public void Rejects_more_than_the_batch_limit_before_processing_files()
    {
        var file = new UploadedFile("car.jpg", "image/jpeg", [0xFF, 0xD8, 0xFF, 0x00]);
        var result = DocumentUploadValidator.Validate(Enumerable.Repeat(file, DocumentUploadValidator.MaximumFileCount + 1).ToList());

        Assert.False(result.IsValid);
        Assert.Equal("TOO_MANY_DOCUMENTS", result.ErrorCode);
    }
}
