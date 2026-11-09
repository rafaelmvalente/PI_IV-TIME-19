// Caique Vasconcelos Naimi - 25004208
// Data: 09/11/2026
// Descrição: Resposta do servidor à validação: se o telefone é válido e uma mensagem
// explicando o motivo quando não for.

public class Resultado extends Comunicado
{
    private boolean valido;
    private String  mensagem;

    public Resultado (boolean valido, String mensagem)
    {
        this.valido   = valido;
        this.mensagem = mensagem;
    }

    public boolean getValido ()
    {
        return this.valido;
    }

    public String getMensagem ()
    {
        return this.mensagem;
    }

    public String toString ()
    {
		return ((this.valido?"VALIDO":"INVALIDO")+" - "+this.mensagem);
	}

}
