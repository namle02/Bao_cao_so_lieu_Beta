using System;
using System.Globalization;
using System.Windows.Data;

namespace BaoCaoSoLieu.Converter
{
    public class LoadingTextConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isLoading)
            {
                if (isLoading)
                {
                    return "Đang tải...";
                }
                else
                {
                    return parameter?.ToString() ?? "Lọc dữ liệu";
                }
            }
            return parameter?.ToString() ?? "Lọc dữ liệu";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
} 