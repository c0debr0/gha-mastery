using PositionSizer.Core;

namespace PositionSizer.App;

public partial class Form1 : Form
{
    public Form1()
    {
        InitializeComponent();
        contractBox.DataSource = Contract.All.ToList();
        contractBox.DisplayMember = nameof(Contract.Symbol);
        Text = $"Position Sizer {Application.ProductVersion}";
    }

    private void calculateButton_Click(object? sender, EventArgs e)
    {
        try
        {
            var contract = (Contract)contractBox.SelectedItem!;
            int max = PositionSizing.MaxContracts(contract, riskInput.Value, stopInput.Value);
            resultLabel.Text = $"Max contracts: {max}";
        }
        catch (ArgumentOutOfRangeException ex)
        {
            resultLabel.Text = ex.Message;
        }
    }
}
