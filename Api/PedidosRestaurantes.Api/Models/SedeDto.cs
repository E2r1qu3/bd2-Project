namespace PedidosRestaurantes.Api.Models;

public class SedeDto
{
    public int SedeId { get; set; }
    public int RestauranteId { get; set; }
    public string Nombre { get; set; } = "";
    public string Provincia { get; set; } = "";
    public string Canton { get; set; } = "";
    public string DireccionExacta { get; set; } = "";
    public string? Telefono { get; set; }
    public TimeSpan HoraApertura { get; set; }
    public TimeSpan HoraCierre { get; set; }
    public bool OfreceExpress { get; set; }
    public bool Activa { get; set; }
}