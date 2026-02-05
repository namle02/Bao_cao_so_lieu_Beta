using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Message
{
    public class LoadDataMessage
    {
        public string? message { get; }
        public DateTime? tuNgay { get; }
        public DateTime? denNgay { get; }

        public LoadDataMessage(string _message, DateTime? _tuNgay, DateTime? _denNgay)
        {
            message = _message;
            tuNgay = _tuNgay;
            denNgay = _denNgay;
        }
    }
}
