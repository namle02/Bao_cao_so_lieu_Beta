using BaoCaoSoLieu.Services.Interface;
using System.Configuration;
using System.Net.Http;
using System.Text.Json;


namespace BaoCaoSoLieu.Services.Implement
{
    public class ConfigServices : IConfigServices
    {
        // HttpClient static đúng chuẩn
        private static readonly HttpClient httpClient = new HttpClient();

        // Singleton instance do DI quản lý, không tự tạo
        public Dictionary<string, string> ConfigList { get; private set; } = new Dictionary<string, string>();

        public async Task GetConfig()
        {
            var configUrl = ConfigurationManager.AppSettings["ConfigUrl"];
            if (string.IsNullOrEmpty(configUrl)) return;

            var response = await httpClient.GetAsync(configUrl);
            response.EnsureSuccessStatusCode();

            string json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);
            var values = doc.RootElement.GetProperty("values");
            foreach (var row in values.EnumerateArray())
            {
                if(row.GetArrayLength() >= 2)
                {
                    var key = row[0].GetString();
                    var value = row[1].GetString();
                    if (!string.IsNullOrEmpty(key) && value != null)
                    {
                        ConfigList[key] = value;
                    }
                }
            }
        }
    }
}
