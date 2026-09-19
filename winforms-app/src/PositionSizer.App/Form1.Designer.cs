namespace PositionSizer.App;

partial class Form1
{
    private System.ComponentModel.IContainer components = null!;
    private ComboBox contractBox = null!;
    private NumericUpDown riskInput = null!;
    private NumericUpDown stopInput = null!;
    private Button calculateButton = null!;
    private Label resultLabel = null!;

    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null)) components.Dispose();
        base.Dispose(disposing);
    }

    private void InitializeComponent()
    {
        components = new System.ComponentModel.Container();
        var layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, Padding = new Padding(12) };
        contractBox = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 140 };
        riskInput = new NumericUpDown { Maximum = 100000, Value = 200, DecimalPlaces = 2, Width = 140 };
        stopInput = new NumericUpDown { Maximum = 1000, Value = 20, DecimalPlaces = 2, Increment = 0.25m, Width = 140 };
        calculateButton = new Button { Text = "Calculate", AutoSize = true };
        resultLabel = new Label { AutoSize = true, Text = "Max contracts: -" };
        calculateButton.Click += calculateButton_Click;

        layout.Controls.Add(new Label { Text = "Contract", AutoSize = true }, 0, 0);
        layout.Controls.Add(contractBox, 1, 0);
        layout.Controls.Add(new Label { Text = "Max risk ($)", AutoSize = true }, 0, 1);
        layout.Controls.Add(riskInput, 1, 1);
        layout.Controls.Add(new Label { Text = "Stop (points)", AutoSize = true }, 0, 2);
        layout.Controls.Add(stopInput, 1, 2);
        layout.Controls.Add(calculateButton, 1, 3);
        layout.Controls.Add(resultLabel, 1, 4);

        AutoScaleMode = AutoScaleMode.Font;
        ClientSize = new Size(360, 220);
        Controls.Add(layout);
    }
}
