namespace BaoCaoSoLieu.Message
{
    public class ExcelExportMessage
    {
        public bool Success { get; }
        public string FilePath { get; }
        public string Message { get; }

        public ExcelExportMessage(bool success, string filePath, string message)
        {
            Success = success;
            FilePath = filePath;
            Message = message;
        }
    }
} 