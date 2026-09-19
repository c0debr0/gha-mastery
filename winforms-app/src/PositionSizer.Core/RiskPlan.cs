namespace PositionSizer.Core;

/// <summary>Value object: the futures contract being traded.</summary>
public sealed record Contract(string Symbol, decimal TickSize, decimal TickValue)
{
    public static readonly Contract MNQ = new("MNQ", 0.25m, 0.50m);
    public static readonly Contract NQ  = new("NQ",  0.25m, 5.00m);
    public static readonly Contract MES = new("MES", 0.25m, 1.25m);
    public static readonly Contract ES  = new("ES",  0.25m, 12.50m);

    public static IReadOnlyList<Contract> All { get; } = [MNQ, NQ, MES, ES];
}

/// <summary>Domain service: "How many contracts can I trade without risking more than X?"</summary>
public static class PositionSizing
{
    public static int MaxContracts(Contract contract, decimal maxRiskDollars, decimal stopPoints)
    {
        if (maxRiskDollars <= 0) throw new ArgumentOutOfRangeException(nameof(maxRiskDollars), "Risk must be positive.");
        if (stopPoints <= 0) throw new ArgumentOutOfRangeException(nameof(stopPoints), "Stop must be positive.");

        decimal ticks = stopPoints / contract.TickSize;
        decimal riskPerContract = ticks * contract.TickValue;
        return (int)Math.Floor(maxRiskDollars / riskPerContract);
    }
}
