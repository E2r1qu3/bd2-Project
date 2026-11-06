// MenuItemDto.cs
namespace PedidosRestaurantes.Api.Models;

public class MenuItemDto
{
    public int CategoriaId { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public int ProductoId { get; set; }
    public string Producto { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public decimal Precio { get; set; }
    public string? ImagenUrl { get; set; }
}