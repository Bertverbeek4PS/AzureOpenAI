codeunit 50100 "Azure Open AI"
{
    trigger OnRun()
    begin

    end;

    internal procedure PostDalle2(Caption: Text; Resolution: Text; var InStr: InStream)
    var
        Method: Option Get,Post,Patch;
        Body: Text;
        JObjBody: JsonObject;
    begin
        //         {
        //     "caption": "create a waterpainting of the construction industry",
        //     "resolution": "1024x1024"
        // }

        JObjBody.Add('caption', Caption);
        JObjBody.Add('resolution', Resolution);

        JObjBody.WriteTo(Body);

        RequestMessage(GetAzureOpenAIEndpoint(), Method::Post, Body, InStr);
    end;

    local procedure RequestMessage(Uri: Text; Method: Option Get,Post,Patch; Body: Text; var InStr: InStream)
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        AccessToken: Text;
        JsonContent: Text;
        JsonResponse: JsonObject;
        JsonTknContentUrl: JsonToken;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RetryAfter: list of [Text];
        operationlocation: list of [Text];
        Int: Integer;
    begin
        AccessToken := GetAzureOpenAIKey();

        RequestMessage.Method(format(Method));
        RequestMessage.SetRequestUri(Uri);

        if Method = Method::Post then begin
            HttpContent.WriteFrom(body);
            HttpContent.GetHeaders(ContentHeaders);
            ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            ContentHeaders.Add('api-key', AccessToken);
            RequestMessage.Content(HttpContent);
        end;

        Client.DefaultRequestHeaders().Add('Accept', 'application/json');

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.HttpStatusCode = 202 then begin
                ResponseMessage.Headers.GetValues('retry-after', RetryAfter);
                ResponseMessage.Headers.GetValues('operation-location', operationlocation);
                Evaluate(Int, RetryAfter.Get(1));
                sleep(Int * 1000);
                //Get the result
                Clear(RequestMessage);
                Clear(Client);
                RequestMessage.Method(format(Method::Get));
                ContentHeaders.Remove('Content-Type');
                Client.DefaultRequestHeaders().Add('Accept', 'application/json');
                Client.DefaultRequestHeaders().Add('api-key', AccessToken);
                RequestMessage.SetRequestUri(operationlocation.Get(1));
                Client.Send(RequestMessage, ResponseMessage);
                if ResponseMessage.HttpStatusCode = 200 then begin
                    ResponseMessage.Content().ReadAs(JsonContent);
                    JsonResponse.ReadFrom(JsonContent);
                    JsonResponse.SelectToken('result.contentUrl', JsonTknContentUrl);

                    //Downlload the image
                    Clear(RequestMessage);
                    Clear(Client);
                    RequestMessage.Method(format(Method::Get));
                    RequestMessage.SetRequestUri(JsonTknContentUrl.AsValue().AsText());
                    Client.Send(RequestMessage, ResponseMessage);
                    ResponseMessage.Content.ReadAs(InStr);
                end;

            end;
    end;

    local procedure GetAzureOpenAIEndpoint(): Text
    var
        AzureOpenAIEndpoint: Text;
    begin
        AzureOpenAIEndpoint := '';
        exit(AzureOpenAIEndpoint);
    end;

    local procedure GetAzureOpenAIKey(): Text
    var
        AzureOpenAIKey: Text;
    begin
        AzureOpenAIKey := '';
        exit(AzureOpenAIKey);
    end;
}