using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Message
{
    public class ErrorMessage
    {
        public string message { get; }
        public ErrorMessage(string Message)
        {
            this.message = Message;
        }
    }
}
