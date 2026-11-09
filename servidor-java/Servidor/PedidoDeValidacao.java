// Caique Vasconcelos Naimi - 25004208
// Data: 09/11/2026
// Descrição: Mensagem enviada pelo cliente com o telefone a ser validado.

public class PedidoDeValidacao extends Comunicado
{
    private String telefone;

    public PedidoDeValidacao (String telefone)
    {
        this.telefone = telefone;
    }

    public String getTelefone ()
    {
        return this.telefone;
    }

    public String toString ()
    {
        return (""+this.telefone);
    }
}
