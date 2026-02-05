using BaoCaoSoLieu.ViewModel.ControlViewModel;
using CommunityToolkit.Mvvm.ComponentModel;

namespace BaoCaoSoLieu.ViewModel
{
    public partial class MainViewModel : ObservableObject
    {
        [ObservableProperty]
        private TabControlVM _tabControlVM;
        public MainViewModel(TabControlVM tabControlVM)
        {
            _tabControlVM = tabControlVM;
        }
    }
}
