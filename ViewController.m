#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE"        //Service's UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //Characteristic's UUID

@interface ViewController ()

@property (strong,nonatomic) CBCentralManager *centralManager;      //Central Manager
@property (strong,nonatomic) NSMutableArray *peripherals;           //Peripherals Manager
@property (weak) IBOutlet NSTextField *log;                         //log

@end

@implementation ViewController


#pragma mark - Contral UI Events
- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - UI Events

- (IBAction)startClick:(NSButton *)sender {
    //Create central manager
    _centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
}


#pragma mark - CBCentralManager's delegates
//Central's state update
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE opened.");
            [self writeToLog:@"BLE opened."];
            //Scan peripherals
            // [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
            
        default:
            NSLog(@"This device didn't support BLE or Bluetooth didn't open.");
            [self writeToLog:@"This device didn't support BLE or Bluetooth didn't open."];
            break;
    }
}



/**
 *  Discovery peripheral
 *
 *  @param central           central device
 *  @param peripheral        peripheral device
 *  @param advertisementData characteristics data
 *  @param RSSI              siganl
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"Found peripheral...");
    [self writeToLog:@"Found peripheral..."];
    
    //Stop scan
    [self.centralManager stopScan];
    
    //Connect to peripheral
    if (peripheral) {
        if(![self.peripherals containsObject:peripheral]){
            [self.peripherals addObject:peripheral];
        }
        NSLog(@"Start to connect to peripheral...");
        [self writeToLog:@"Start to connect to peripheral..."];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
}


//Connect to peripheral
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"Successfully connect to peripheral!");
    [self writeToLog:@"Successfully connect to peripheral!"];
    
    //Set the delegate of peripheral as the contraller of UI
    peripheral.delegate=self;
    
    //looking for the services from peripheral
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}



//Fail to connect to peripheral
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Fail to connect to peripheral!");
    [self writeToLog:@"Fail to connect to peripheral!"];
}





#pragma mark - CBPeripheral's delegate



//After peripheral found the services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"Discoveried useful services...");
    [self writeToLog:@"Discoveried useful services..."];
    
    if(error){
        NSLog(@"When peripheral is looking for the service, there is error. Error information:%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"When peripheral is looking for the service, there is error. Error information:%@",error.localizedDescription]];
    }
    
    //Search all services
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    
    NSLog(@"Servers count:%lu", peripheral.services.count);
    @try {
        for (CBService *service in peripheral.services) {
            //NSLog(@"Service's UUID:");
            if([service.UUID isEqual:serviceUUID]){
                
                //Looking for the special charateristic
                [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
            }
        }
    } @catch (NSException *exception) {
        @throw exception;
    } @finally {
    
    }
    
}

//After peripheral found characteristic
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"Found useful characteristic...");
    [self writeToLog:@"Found useful characteristic..."];
    
    if (error) {
        NSLog(@"When peripheral is looking for characterist, there is an error. Error information：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"When peripheral is looking for characterist, there is an error. Error information%@",error.localizedDescription]];
    }
    
    //Search all characteristics in peripheral
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    
    if ([service.UUID isEqual:serviceUUID]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
                //                [peripheral readValueForCharacteristic:characteristic];
                //                    if(characteristic.value){
                //                    NSString *value=[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                //                    NSLog(@"Read characteristic：%@",value);
                //                }
            }
        }
    }
    
}



//After characterist has been updated...
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"Received message that characterist has been updated...");
    [self writeToLog:@"Received message that characterist has been updated..."];
    
    if (error) {
        NSLog(@"When receiving the message, there is an error. Error information%@",error.localizedDescription);
    }
    
    //Received the new value of characterist
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    if ([characteristic.UUID isEqual:characteristicUUID]) {
        if (characteristic.isNotifying) {
            if (characteristic.properties==CBCharacteristicPropertyNotify) {
                NSLog(@"Received the message.");
                [self writeToLog:@"Received the message."];
                return;
            }else if (characteristic.properties ==CBCharacteristicPropertyRead) {
                //update the delegate of peripheral-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                [peripheral readValueForCharacteristic:characteristic];
            }
            
        }else{
            NSLog(@"Stoped");
            [self writeToLog:@"Stopped"];
            
            //Cancel connection
            [self.centralManager cancelPeripheralConnection:peripheral];
        }
    }
}



//After characteristic updated, involve readValueForCharacteristic method
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"When characteristic is updated, there is an error. Error information：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"When characteristic is updated, there is an error. Error information：%@",error.localizedDescription]];
        return;
    }
    
    if (characteristic.value) {
        NSString *value=[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Read the value of characteristic：%@",value);
        [self writeToLog:[NSString stringWithFormat:@"Read the value of characteristic：%@",value]];
    }else{
        NSLog(@"Didn't find the value of characteristic.");
        [self writeToLog:@"Didn't find the value of characteristic."];
    }
}




#pragma mark - Properties
-(NSMutableArray *)peripherals{
    if(!_peripherals){
        _peripherals=[NSMutableArray array];
    }
    return _peripherals;
}



#pragma mark - private methods
/**
 *  Record log
 *
 *  @param info log information.
 */
-(void)writeToLog:(NSString *)info{
    self.log.stringValue=[NSString stringWithFormat:@"%@\r\n%@",self.log.stringValue,info];
}

@end
