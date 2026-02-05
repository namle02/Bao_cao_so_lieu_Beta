using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Message
{
    public class ClearDataMessage
    {
        public string? message { get; }

        public ClearDataMessage(string? _message = null)
        {
            message = _message ?? "Clear data";
        }
    }
} 