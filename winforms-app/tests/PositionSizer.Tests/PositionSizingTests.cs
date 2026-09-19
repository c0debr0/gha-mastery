using PositionSizer.Core;

namespace PositionSizer.Tests;

public class PositionSizingTests
{
    [Fact]
    public void Mnq_200_dollars_risk_with_20_point_stop_is_5_contracts()
    {
        // 20 points / 0.25 = 80 ticks; 80 * $0.50 = $40 per contract; $200 / $40 = 5
        Assert.Equal(5, PositionSizing.MaxContracts(Contract.MNQ, 200m, 20m));
    }

    [Fact]
    public void Rounds_down_never_up()
    {
        // NQ 10 pts = 40 ticks * $5 = $200/contract; $500 / $200 = 2.5 -> 2
        Assert.Equal(2, PositionSizing.MaxContracts(Contract.NQ, 500m, 10m));
    }

    [Fact]
    public void Zero_stop_is_rejected()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => PositionSizing.MaxContracts(Contract.ES, 500m, 0m));
    }
}
