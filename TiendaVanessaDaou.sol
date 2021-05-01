// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Tienda {
    
    struct Producto{
        string nombre;
        uint256 numero_unidades;
        uint256 precio_base_unitario;
        string descripcion;
        
    }
    
    struct Cliente{
        string nombre;
        string pais;
        uint256 gastado;
        uint256 deuda;
    }
    
    address payable private vendedor;
    uint256 private _ingreso_global;
    uint256 private _deuda_global;
    uint256 private _intentos_destruccion = 0;
    
    mapping(string=>Producto) private productos;
    mapping(address=>Cliente) private clientes;
    mapping(uint256=>address) private codigo_address_cliente;
    mapping(string=>uint256) private ingresos_totales_pais;
    
    
    modifier soloVendedor(){
        require(msg.sender == vendedor,"Solo puede hacer esto el vendedor");
        _;
    }
    
    modifier clienteUnico(uint256 _codigo){
        require(codigo_address_cliente[_codigo] == address(0) && bytes(clientes[msg.sender].nombre).length == 0 ,"El cliente debe ser unico");
        _;
    }
    
    modifier productoUnico(string memory _nombre){
        require(bytes(productos[_nombre].descripcion).length ==0 ,"El producto debe ser unico");
        _;
    }
    
    modifier esCliente(){
        require(bytes(clientes[msg.sender].nombre).length != 0,"Debes registrarte primero");
        _;
    }
    
    modifier existeProducto(string memory _nombre){
        require(bytes(productos[_nombre].descripcion).length !=0,"El producto consutlado no existe");
        _;
    }
    
    modifier existePais(string memory _pais){
        require(ingresos_totales_pais[_pais] !=0,"No se han registrado ganancias para este pais");
        _;
    }
    
    modifier sinDeuda(){
        require(clientes[msg.sender].deuda == 0,"Tienes una deuda pendiente");
        _;
    }
    
    modifier conDeuda(){
        require(clientes[msg.sender].deuda > 0,"No tienes ninguna deuda pendiente");
        _;
    }
    
    modifier valorExacto(string memory _nombre){
        uint256 valor_final = productos[_nombre].precio_base_unitario;
        if(clientes[msg.sender].gastado > 50 ether && (valor_final- 3 ether) >=0){
            valor_final = valor_final - 3 ether;
        }
        require(msg.value == valor_final,"Debes enviar solo el valor exacto de la compra");
        _;
    }
    
    modifier deudaExacta(){
        require(msg.value == clientes[msg.sender].deuda,"Debes enviar el dinero exacto de la deuda");
        _;
    }
    
    modifier unidadesDisponibles(string memory _nombre){
        require(productos[_nombre].numero_unidades > 0,"No hay unidades disponibles del producto");
        _;
    }
    
    
    constructor() {
        vendedor = payable(msg.sender);
    }
    
    function registrarCliente(uint256  _codigo,string memory _nombre, string memory _pais) public 
     clienteUnico(_codigo)  {
        Cliente memory cliente;
        cliente.nombre = _nombre;
        cliente.pais = _pais;
        codigo_address_cliente[_codigo] = msg.sender;
        clientes[msg.sender] = cliente;
    }
    
    
    function registrarProducto(string memory _nombre, uint256  _numero_unidades,uint256  _precio_base_unitario, string memory _descripcion) public 
     soloVendedor
     productoUnico(_nombre)  {
            
        Producto  memory producto;
        producto.nombre = _nombre;
        producto.numero_unidades = _numero_unidades;
        producto.precio_base_unitario = _precio_base_unitario * 1 ether;
        producto.descripcion = _descripcion;
        
        productos[_nombre] = producto;
    }
    
    
    function consultarProducto(string memory _nombre)public view 
    esCliente()
    existeProducto(_nombre)
    sinDeuda()
    returns(string memory nombre, uint256 numero_unidades, uint256 precio_base_unitario, string memory descripcion, uint256 valor_final) 

    {
        Producto memory producto = productos[_nombre];
        Cliente memory cliente = clientes[msg.sender];
        nombre = producto.nombre;
        numero_unidades = producto.numero_unidades;
        precio_base_unitario = producto.precio_base_unitario;
        descripcion = producto.descripcion;
        valor_final = producto.precio_base_unitario;
        if((cliente.gastado > 1 ether) && (valor_final-3 ether) >=0 ether){
            valor_final = valor_final - 3 ether;
        }
        
    }
    
    
    function comprar(string memory _nombre)public payable 
    esCliente()
    sinDeuda()
    existeProducto(_nombre)
    unidadesDisponibles(_nombre)
    valorExacto(_nombre)
    {
        productos[_nombre].numero_unidades = productos[_nombre].numero_unidades - 1;
        clientes[msg.sender].gastado = clientes[msg.sender].gastado + msg.value ;
        _ingreso_global = _ingreso_global + msg.value;
        ingresos_totales_pais[clientes[msg.sender].pais] = ingresos_totales_pais[clientes[msg.sender].pais] + msg.value;
    
    }
    
    
    function comprarFiado(string memory _nombre)public 
    esCliente()
    sinDeuda()
    existeProducto(_nombre)
    unidadesDisponibles(_nombre)
    {
        uint256 valor_final = productos[_nombre].precio_base_unitario;
        if(clientes[msg.sender].gastado > 50 ether && (valor_final- 3 ether) >=0){
            valor_final = valor_final - 3 ether;
        }
        productos[_nombre].numero_unidades = productos[_nombre].numero_unidades - 1;
        clientes[msg.sender].deuda = clientes[msg.sender].deuda + valor_final;
        _deuda_global= _deuda_global + valor_final;
        
    }
    
    function consultarDeuda()public view
    esCliente()
    returns(uint256 deuda) 
    {
        deuda = clientes[msg.sender].deuda;
        
    }
    
    function pagarDeuda()public payable 
    esCliente()
    conDeuda()
    deudaExacta()
    {
        clientes[msg.sender].deuda = 0;
        _ingreso_global = _ingreso_global + msg.value;
        _deuda_global= _deuda_global - msg.value;
        ingresos_totales_pais[clientes[msg.sender].pais] = ingresos_totales_pais[clientes[msg.sender].pais] + msg.value;
    }
    
    function consultarGastos()public view
    esCliente()
    returns(uint256 gastado) 
    {
        gastado = clientes[msg.sender].gastado;
    }
    
    function consultarIngresosTotales()public view
    soloVendedor()
    returns(uint256 ingreso_global) 
    {
        ingreso_global = _ingreso_global;
    }
    
    function consultarDeudaGlobal()public view
    soloVendedor()
    returns(uint256 deuda_global) 
    {
        deuda_global = _deuda_global;
    }
    
    
    function consultarIngresosPorPais(string memory _pais)public view
    soloVendedor()
    existePais(_pais)
    returns(uint256 gastado_pais) 
    {
        gastado_pais = ingresos_totales_pais[_pais];
    }
    
    function destuirTienda() public
    soloVendedor()
    returns (string memory mensaje){
        if(_intentos_destruccion == 2){
            selfdestruct(vendedor);
        }else{
            _intentos_destruccion = _intentos_destruccion + 1;
        }
        mensaje = "Intentos insuficientes";
        
    }
}