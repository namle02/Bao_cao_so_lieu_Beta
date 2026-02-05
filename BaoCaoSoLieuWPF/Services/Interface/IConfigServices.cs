using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Services.Interface
{
    public interface IConfigServices
    {
        Dictionary<string, string> ConfigList { get; }
        Task GetConfig();
    }
}
