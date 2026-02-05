using System.Windows;
using BaoCaoSoLieu.ViewModel;

namespace BaoCaoSoLieu;

/// <summary>
/// Interaction logic for MainWindow.xaml
/// </summary>
public partial class MainWindow : Window
{
    public MainWindow(MainViewModel vm)
    {
        InitializeComponent();
        DataContext = vm;
    }
}
