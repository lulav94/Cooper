pragma solidity ^0.5.11;
    //pragma solidity >=0.4.22 <0.6.0;
    
    import "./project.sol";
    import "./ownable.sol";
    
    contract Cooperativa is Ownable {
        
        event NewProject(uint projectId, uint tokensNumber, uint price);
        event ProjectStarted(uint projectId);
        event NewMember(uint memberId, string name);
        event MemberDeleted(uint memberId, string name);
        
        uint totalMembers; //Descriu els membres totals de la coperativa
        
        constructor () public {
            totalMembers = 0; //Inicialment hi ha 0 membres
        }
        
        struct Member {  //Struct que defineix les variables que te cada Membre de la cooperativa
            string name;
        }
        
        Project[] public projects;
        Member[] public members;
        
        
        //Identifica a quina adreça es correspon cada membre
        mapping (uint => address) public memberToAddress;
        //Identifica a quina adreça pertany cada projecte
        mapping (uint => address) public projectToOwner;
        //Du el compte de Projectes de cada adreça
        mapping (address => uint) ownerProjectCount;
        
        
        
        //Metode per proposar un Projecte (nomes funciona si ets un membre de la cooperativa)
        function createProject(uint _tokensNumber, uint _price, uint _timeToLive) public onlyMember {
            //Cream el contracte Project
            Project projecte = new Project(projects.length,_tokensNumber,_price,_timeToLive,msg.sender);
            //Acutalitzam els mappings
            uint id = projects.push(projecte) - 1;
            projectToOwner[id] = msg.sender;
            ownerProjectCount[msg.sender]++;
            
            emit NewProject(id, _tokensNumber, _price);
        }
        
        //Intentam iniciar el projecte indicat, per poder-ho fer hem de ser l'owner del projecte
        function startProject(uint _projectID) public onlyMember{
            //Comprovam si els tokens s'han venut completament
            projects[_projectID].tryStartProject(msg.sender);
            
        }
        
        //Funcio que ens retorna true si el temps del projecte ja ha passat i que retorna false en cas contrari
        function projectState(uint _projectID) public view returns (bool){
            return projects[_projectID].getProjectState();
        }
        
        //Metode que ens retorna el preu a pagar per la cuantitat de tokens indicada
        function TokenPrice(uint _projectID, uint quantity) public view returns(uint priceTokens){
            priceTokens = quantity * projects[_projectID].getTokenPrice();
            return priceTokens;
        }
        
        //Metode per comprar tokens d'un dels projectes proposats, s'ha de ser membre
        function buyTokens(uint _projectID, uint _quantity) public payable onlyMember {
            projects[_projectID].enoughToBuy(_quantity); //Comprovam amb aquest metode que els tokens que es volen comprar estan disponibles al projecte en cuestio.
            
            uint priceToPay = TokenPrice(_projectID,_quantity); //Calculam el valor que s'ha de pagar en total
            require(priceToPay == msg.value); //El preu a pagar per comprar els tokens ha de ser igual al value introduit
            
            address(projects[_projectID]).transfer(priceToPay); //Pagam i si el pagament ha estat correcte, donam els tokens, transfer retorna error si el pagament no es du a terme
            projects[_projectID].buyToken(_quantity,msg.sender);
           
        }
        
        //Metode que torna els tokens que te dins el projecte indicat el membre que executa la cridada
        function TokensLeft(uint _projectID) public view returns(uint){
            return projects[_projectID].getTokensLeft();
        }
        
        //Indica els tokens que te el msg.sender del projecte indicat
        function howMuchTokens(uint _projectID) public view onlyMember returns(uint) {
            return projects[_projectID].getTokens(msg.sender);
        }
        
        //Metode que intenta reembolsar els ether invertits en tokens en cas dae que el projecte no s'hagi duit a terme
        function tryRefundTokens(uint _projectID) public onlyMember{
            projects[_projectID].refundTokens(msg.sender);
        }
        
        //Metode que retorna els ethers que te una instancia del contracte projecte. (els ethers que ja s'han invertit en el projecte)
        function getBalanceProject(uint _projectID) public view returns(uint){
            return projects[_projectID].getBalance();
        }
        
        //Metode per ficar membres nous a la cooperativa (requereix que la adreça no sigui un membre)
        function createMember(string memory _name) public allButMember {
            //Introduim el membre a la llista de membres
            uint id = members.push(Member(_name)) - 1;
            memberToAddress[id] = msg.sender;
            totalMembers++;
            
            emit NewMember(id, _name);
        }
        
        //Metode per eliminar membres existens de la cooperativa
        function deleteMember(uint userID) public onlyOwner {
            for(uint i=0 ; i<projects.length ; i++){
                if(memberToAddress[userID]==projectToOwner[i]){
                    delete projectToOwner[i];
                    delete projects[i];
                }  
            }
            emit MemberDeleted(userID, members[userID].name);
            delete members[userID];
            delete memberToAddress[userID];
            
        }
        
        
        
        //Metode que retorna true si el msg.sender es un membre
        function isMember() public view returns(bool) {
            for(uint i=0 ; i < members.length ; i++){
                if(memberToAddress[i]==msg.sender){
                    return true;
                }
            }
            return false;
        }
        
        //Modifier que nomes permet exectuar la funcio a els membres de la cooperativa
        modifier onlyMember() {
            require(isMember());
            _;
        }
        //Modifier que nomes permet exectuar la funcio als que no son membres
        modifier allButMember(){
            require(!isMember());
            _;
        }
    
        
    }