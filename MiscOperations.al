codeunit 50100 MiscOperations
{
    procedure Ping(input: Integer): Integer
    begin
        exit(-input);
    end;

    procedure Delay(delayMilliseconds: Integer)
    begin
        Sleep(delayMilliseconds);
    end;

    procedure GetLengthOfStringWithConfirmation(inputJson: Text): Integer
    var
        c: JsonToken;
        input: JsonObject;
    begin
        input.ReadFrom(inputJson);
        if input.Get('confirm', c) and c.AsValue().AsBoolean() = true and input.Get('str', c) then
            exit(StrLen(c.AsValue().AsText()))
        else
            exit(-1);
    end;

    procedure GetCustomer(input: Code[20]): Text
    var
        Cust: Record Customer;
        CustJsonObject: JsonObject;
    begin
        if Cust.Get(input) then begin
            CustJsonObject.Add('CustNo', Cust."No.");
            CustJsonObject.Add('CustName', Cust.Name);
            CustJsonObject.Add('CountryCode', Cust."Country/Region Code");
            CustJsonObject.Add('PhoneNo', Cust."Phone No.");
        end;
        exit(Format(CustJsonObject));
    end;

    procedure GetCustomer2(custNo: Code[20]): Text
    var
        Cust: Record Customer;
        custName: Text[100];
        countryCode: Code[10];
        phoneNo: Text[30];
    begin
        if Cust.Get(custNo) then begin
            custNo := Cust."No.";
            custName := Cust.Name;
            countryCode := Cust."Country/Region Code";
            phoneNo := Cust."Phone No.";
        end;
        exit(StrSubstNo('CustNo: %1, CustName: %2, CountryCode: %3, PhoneNo: %4', custNo, custName, countryCode, phoneNo));
    end;

    procedure CreateNewCustomer(inputJson: Text): Text
    var
        CustJsonResponse: JsonObject;
        CustJsonToken: JsonToken;
        Customer: Record Customer;
        CustNo: Code[20];
        CustName: Text[100];
        CountryCode: Code[10];
        PhoneNo: Text[30];
    begin
        CustJsonResponse.ReadFrom(inputJson);
        Customer.Init();
        if CustJsonResponse.Get('CustNo', CustJsonToken) then begin
            CustNo := CustJsonToken.AsValue().AsText();
            Customer.Validate("No.", CustNo);
        end;
        if CustJsonResponse.Get('CustName', CustJsonToken) then begin
            CustName := CustJsonToken.AsValue().AsText();
            Customer.Validate(Name, CustName);
        end;
        if CustJsonResponse.Get('CountryCode', CustJsonToken) then begin
            CountryCode := CustJsonToken.AsValue().AsText();
            Customer.Validate("Country/Region Code", CountryCode);
        end;
        if CustJsonResponse.Get('PhoneNo', CustJsonToken) then begin
            PhoneNo := CustJsonToken.AsValue().AsCode();
            Customer.Validate("Phone No.", PhoneNo);
        end;
        if Customer.Insert(true) then
            exit(StrSubstNo('Customer %1 Created Successfully', Customer."No."))
        else
            exit('Customer Creation Failed');
    end;

    procedure CreateNewCustomer2(custNo: Code[20]; custName: Text[100]; countryCode: Code[10]; phoneNo: Text[30]): Text
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer.Validate("No.", custNo);
        Customer.Validate(Name, custName);
        Customer.Validate("Country/Region Code", countryCode);
        Customer.Validate("Phone No.", phoneNo);
        if Customer.Insert(true) then
            exit(StrSubstNo('Customer %1 Created Successfully', Customer."No."))
        else
            exit('Customer Creation Failed');
    end;

    procedure ImportAttachmentToCustomer(inputJson: Text): Text
    var
        CustJsonResponse: JsonObject;
        CustJsonToken: JsonToken;
        Customer: Record Customer;
        CustNo: Code[20];
        AttachmentBase64: Text;
        FileName: Text[100];
        FileExtension: Text[10];
        DocAttach: Record "Document Attachment";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
        TempBlob: Codeunit "Temp Blob";
        ImportSuccess: Boolean;
    begin
        AttachmentBase64 := '';
        FileName := '';
        FileExtension := '';
        ImportSuccess := false;
        CustJsonResponse.ReadFrom(inputJson);
        if CustJsonResponse.Get('CustNo', CustJsonToken) then
            if Customer.Get(CustJsonToken.AsValue().AsText()) then
                if CustJsonResponse.Get('AttachmentBase64', CustJsonToken) then begin
                    AttachmentBase64 := CustJsonToken.AsValue().AsText();
                    if AttachmentBase64 <> '' then begin
                        CustJsonResponse.Get('FileName', CustJsonToken);
                        FileName := CustJsonToken.AsValue().AsText();
                        CustJsonResponse.Get('FileExtension', CustJsonToken);
                        FileExtension := CustJsonToken.AsValue().AsText();
                        TempBlob.CreateOutStream(OutStr);
                        Base64Convert.FromBase64(AttachmentBase64, OutStr);
                        TempBlob.CreateInStream(InStr);
                        DocAttach.Init();
                        DocAttach.Validate("Table ID", Database::Customer);
                        DocAttach.Validate("No.", Customer."No.");
                        DocAttach.Validate("File Name", FileName);
                        DocAttach.Validate("File Extension", FileExtension);
                        DocAttach."Document Reference ID".ImportStream(InStr, FileName);
                        if DocAttach.Insert(true) then
                            ImportSuccess := true;
                    end;
                end;
        if ImportSuccess then
            exit(StrSubstNo('The attachment %1.%2 is successfully imported into Customer %3', FileName, FileExtension, Customer."No."))
        else
            exit('Attachment Import Failed');
    end;
}
