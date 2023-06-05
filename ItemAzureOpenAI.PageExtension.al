pageextension 50100 ItemCardExt extends "Item Card"
{
    actions
    {
        addlast(Functions)
        {
            action("Create Picture")
            {
                Caption = 'Create Picture';
                Visible = true;

                trigger OnAction()
                var
                    AzureOPenAI: Codeunit "Azure Open AI";
                    InStr: InStream;
                    Txt: text;
                begin
                    AzureOPenAI.PostDalle2(rec.Description, '1024x1024', InStr);
                    rec.Picture.ImportStream(InStr, rec.Description);
                    Rec.Modify(true);
                    CurrPage.Update(true);
                end;
            }
        }
    }
}