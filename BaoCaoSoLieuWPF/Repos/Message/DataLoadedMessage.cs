using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Message
{
    public class DataLoadedMessage
    {
        public string TableName { get; }
        public bool Success { get; }
        public string? ErrorMessage { get; }

        public DataLoadedMessage(string tableName, bool success = true, string? errorMessage = null)
        {
            TableName = tableName;
            Success = success;
            ErrorMessage = errorMessage;
        }
    }
} 