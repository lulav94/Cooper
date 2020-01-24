pragma solidity ^0.5.11;

import "./token.sol";

contract Project{
    
    event BoughtToken(uint projectID, address buyer);
    event RefundedToken(uint projectID, address exBuyer);
    event ProjectStarted(uint projectID);
    
    uint tokensNumber;  //Nombre de tokens del projecte
    uint price;         //Preu total del projecte
    uint tokenPrice;    //Preu a pagar per cada token
    uint timeToDie;   //Moment en el que el projecte s-ha acabat
    
    uint projectID;    //Identificador del projecte
    bool started = false;  //Indica si el projecte ha començat
    TokenERC20 token; //Inicialitzam el el contracte token
    
    address owner; //Identifica a l'owner del projecte
    
    constructor (uint _projectID, uint _tokensNumber, uint _price, uint _timeToLive, address _owner) public {
        
        tokensNumber = _tokensNumber;  //Nombre de tokens del projecte
        price = _price;                //Preu total del projecte
        tokenPrice = _price/_tokensNumber; //Preu a pagar per cada token
        projectID = _projectID; //Identifcador del projecte
        timeToDie = block.timestamp + _timeToLive; //Temps en el que el projecte es donara per acabat
        token = new TokenERC20(_tokensNumber,"tokensProject","TPJ");
        owner = _owner;
        
    }
    
    //Funcio que executa una transfarencia de tokens cap al msg.sender
    function buyToken(uint quantity, address _reciever) public onlyIfNotFinished {
        transferTokenTo(_reciever,quantity);
        token.approve(msg.sender,quantity); //Permetem a la cooperativa vendre els nostres tokens, per un possible futur rembols
    }
    
    //Intenta retornar els ethers invertits en el projecte per l'usuari que executa la funció a canvi de tornar els tokens al contracte projecte
    function refundTokens(address payable _reciever) public onlyIfFinished{
        //Si el temps ha passat pero el projecte s'ha duit a terme, no es poden tornar els tokens:
        require(!started);
        //Primer es tornen els tokens que te l'usuari
        uint tokensBalance = token.balanceOf(_reciever); // tokens balance son els tokens que te l'usuari
        token.transferFrom(_reciever,address(this),tokensBalance);  //Realitzam la transferencia de tokens per retornar els tokens al projecte.
        
        //Despres es tornen els ethers que es troben al contracte
        uint moneyInvested = tokensBalance * tokenPrice; //Valor tatal invertit pel msg.sender en el projecte
        transferEtherTo(_reciever, moneyInvested); //Executam la funcio de transferir ether del contracte projecte
        
    }
    
    //Funcio internal per transferir ether fora del contracte, com que es internal l'executor del send pasa a ser el contracte.
    function transferEtherTo(address payable _reciever, uint weiQuantity) internal {
        _reciever.transfer(weiQuantity);
    }
    
    //Funcio internal per transferir tokens fora del contracte, com que es internal l'executor del transfer pasa a ser el contracte.
    function transferTokenTo(address _reciever, uint TokenQuantity) internal {
        token.transfer(_reciever,TokenQuantity);
    }
    
    //Si el temps no ha passat i s'han venut tots els tokens, es pot executar aquesta funció, la qual bloquetja el projecte en l'estat de començat.
    //Un cop executada correctament aquesta funcio els tokens no es poden tornar i passen a ser "accions" del projecte.
    function tryStartProject(address _owner) public onlyIfNotFinished{
        require(_owner==owner);
        require(getTokensLeft() == 0);
        started = true;
        emit ProjectStarted(projectID);
    
    }
    
    //funcio que retorna l'estat del projecte en cuant al temps, retorna true si el temps no ha passat i retorna false si el temps ja ha passat.
    function getProjectState() public view returns(bool) {
        if (timeToDie>block.timestamp){
            return true;
        }else{
            return false;
        }
    }
    
    //Atura l'execució de la funcio si no hi ha suficients tokens per comprar
    function enoughToBuy(uint _quantity) public view {
        require(getTokensLeft()>=_quantity);
    }
    
    //------------------METODES GET------------------
    
    //Retorna els tokens que queden per vendre
    function getTokensLeft() public view returns(uint256 tokensLeft) {
        tokensLeft = token.balanceOf(address(this));
        return tokensLeft;
    }
    //Retorna els tokens que te l'usuari executant de la funcio
    function getTokens(address _reciever) public view returns(uint256 tokens) {
        return token.balanceOf(_reciever);
    }
    //Retorna el preu d'un token
    function getTokenPrice() public view returns (uint priceOfToken) {
       priceOfToken = tokenPrice;
       return priceOfToken;
    }
    //Retorna el balanç del projecte (quants d'ether s'han invertit en el projecte)
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    // ----------------MODIFIERS------------------
    
    //La funcio nomes s'executa si el projecte encara no ha passat la data limit
    modifier onlyIfNotFinished() {
            require(timeToDie>block.timestamp);
            _;
        }
      
    //La funcio nomes s'executa si el projecte ja ha passat la data limit  
    modifier onlyIfFinished() {
            require(!(timeToDie>block.timestamp));
            _;
        }
        
        //Empty payable fallback method just to receive some
        function() external payable{
    }
    
}