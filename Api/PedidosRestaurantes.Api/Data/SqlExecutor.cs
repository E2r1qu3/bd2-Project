using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace PedidosRestaurantes.Api.Data;
public class SqlExecutor

{
    private readonly string _connectionString;

    public SqlExecutor(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("PedidosDb")
            ?? throw new InvalidOperationException(
                "Falta la cadena de conexión 'PedidosDb' en appsettings.Development.json.");
    }

    public async Task<IEnumerable<T>> QueryAsync<T>(string storedProcedure, object? parametros = null)
    {
        await using var connection = new SqlConnection(_connectionString);

        return await connection.QueryAsync<T>(
            storedProcedure,
            parametros,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<T?> QuerySingleOrDefaultAsync<T>(string storedProcedure, object? parametros = null)
    {
        await using var connection = new SqlConnection(_connectionString);

        return await connection.QuerySingleOrDefaultAsync<T>(
            storedProcedure,
            parametros,
            commandType: CommandType.StoredProcedure);
    }
}