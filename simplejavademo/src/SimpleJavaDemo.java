// testclasse voor opdracht 1 SEV
// todo:
// - ergens constructor toevoegen
// - unit tests?

// total lines = 2 (class level) + 8 + 18 + 18 + 24 + 10 = 80
public class SimpleJavaDemo {
    
	// unit size: 8
	// unit complexity: 1 + 2 = 3
    public static void main(String[] args) {
		//try-catch block
		// complexity + 2
		try{
			doeIets(1000);
		}
		catch (ArithmeticException e) { 
         System.out.println("You should not divide a number by zero");
      }

    }
	
	/*
	* javadoc telt niet mee in line count
	* unit size: 18
	* unit complexity: 1 + 1 + 2 = 4
	*/
	public static void doeIets(int input){
		// een regel commentaar telt ook niet mee
		input = 20000/input;
		
		// while loop complexity + 1
		while (input % 2 == 0){
				System.out.println("een loop verhoogt de cyclische complexiteit");
				input += 2;
		}
		
		//duplicated if
		// complexity + 2 (nested)
		if(input > 10000){
			// nested comment
			// deze versie van de duplicate heeft een extra comment line en een extra whitespace
			
			System.out.println("this is a large number!");
		}
		else{
			if( input > 1000){
				System.out.println("this is a medium number!");
			}
			else{
				System.out.println("this is a small number!");
			}
		}
	}
	
	// unit size: 18
	// unit complexity: 1 + 1 + 2 = 4
	public int doeIetsAnders(int input){
		int retVal = 0;
		
		// for loop complexity + 1
		for(int i = 0; i < input; i++){
			retVal = retVal/2 + 1;			
		}
		
		//duplicated if
		// complexity + 2 (nested)
		if(input > 10000){
			// nested comment
			System.out.println("this is a large number!");
		}
		else{
			if( input > 1000){
				System.out.println("this is a medium number!");
			}
			else{
				System.out.println("this is a small number!");
			}
		}
		// een return moet ook geteld worden
		return retVal;
		
	}
	
	// unit size: 24
	// unit complexity: 1 + 2 + 2 + 3 + 1 = 9s
	public void doeNogMeer(){
		int a = 10;
		int b = 3;
		// extra if (zonder else branch), en een infix
		// complexity + 2
		if(a > b && a%2 == 0){
			a++;
		}
		// nog een if (met else branch) en een infix
		// complexity + 2
		if(a > b || a%2 == 0){
			a++;
		}
		else{
			a = a / 2;
		}
		
		// switch
		// complexity + 3
		switch(a){
			case 12:
				System.out.println("ok");
				break;
			case 11:
				System.out.println("ook ok");
				break;
			default:
				System.out.println("niet ok");	
		}
		
		// and a conditional, because why not
		// complexity + 1
		int max = (a > b) ? a : b;
	}
	
	// unit size: 10
	// unit complexity: 1 + 1 + 1 = 3
	public void blijfMaarDoen(){
		String[] fruits = new String[] { "Orange", "Apple", "Pear", "Strawberry" };
		boolean bool = false;

		//complexity +1
		for (String fruit : fruits) {
			// fruit is an element of the `fruits` array.
			System.out.println("jummy");
		}
		// complexity +1
		do {
		   System.out.println("Dit print één keer zelfs al is de bool false");
		}while(bool);
	}
}