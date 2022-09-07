// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract iecQuiz01{
    uint256 val_01;
    uint256 val_02;
    uint256 resultFinal;

    function seData(uint256 _val01, uint256 _val02) public {
        resultFinal = _val01 + _val02;
    } 

    function getResult() public view returns (uint256){
        return resultFinal;
    } 
}

contract iecQuiz02{

    mapping (address => uint256) public age;

    function setAge(uint256 _age) public {
        age[msg.sender]= _age;
    }

    function getAge() public view returns(uint256){
        return age[msg.sender];
    }

}

contract iecQuiz03{

    address owner;

    constructor(){
        owner = msg.sender;
    }

    struct StudentData{
        // address ad
        string name;
        uint256 age;
        uint256 marks;
        string gender;
        bool dataPresent;
    }

    mapping(address => StudentData) data;
    StudentData[] studentData;


    function addStudentData(string memory _name, uint256 _age, uint256 _marks, string memory _gender) public {
        require(data[msg.sender].dataPresent == false,"data alrady submited");
        studentData.push(StudentData(_name, _age, _marks, _gender, true));
        data[msg.sender]=StudentData(_name, _age, _marks, _gender, true);
    }

    function getDataStudent(address _address) view public returns(StudentData memory){
        require(msg.sender == _address, "You are not Authorize");
        return data[_address];
    }

    function updateStudentData(address _address, string memory _name, uint256 _age, uint256 _marks, string memory _gender) public {
        require(msg.sender == owner,"You are not Authorize, Only Owner can update data");
        data[_address]=StudentData(_name, _age, _marks, _gender, true);
        // studentData[_address]=(_name, _age, _marks, _gender, true);
    }

    // function getAllDataLength() view returns (uint){
    //     return studentData.length;
    // }

    function getDataStudent() public view returns(StudentData[] memory){
       return studentData;
    }

    function getMarks() public view returns(StudentData[] memory){
       return studentData;
    } 

    
}

contract IecQuiz03b {
        address private owner;
        uint256 private rollNo = 1;

   struct Student{
       string name;
       uint256 age;
       uint256 marks;
       string gender;
       uint8 class;
   }

   Student[] students;

   constructor() {
       owner = msg.sender;
   }
   modifier onlyOwner() {
       require(msg.sender == owner, "You are not allowed to do that");
       _;
   }

   function addData(string memory _name, uint256 _age, uint256 _marks,string memory _gender, uint8 _class ) public onlyOwner {
       students.push(Student(_name,_age,_marks,_gender,_class));
       rollNo++;
   }


    function updateData(uint256 _rollNo,string memory _name, uint256 _age, uint256 _marks,string memory _gender, uint8 _class ) public onlyOwner {

       students[_rollNo - 1] = Student(_name,_age,_marks,_gender,_class);

    }

        function showData(uint256 _rollNo) public view returns(Student memory) {
            return students[_rollNo - 1];
    }

    function  allData() public view onlyOwner returns(Student[] memory) {
    return students;
}

    function highestMarks() public view returns (uint256) {
             uint256 result;    
        for(uint256 i = 0; i<students.length; i++) {
            if(students[i].marks > result ) {
            result = students[i].marks;
            }
        }
        return result;
    }
    
    function lowestMarks() public view returns (uint256) {
             uint256 result; 
        for(uint256 i = 0; i<students.length; i++) {
             if(i == 0) {
                 result = students[i].marks;
             }
          if(students[i].marks < result) {
            result = students[i].marks;
            }
        }
        return result;
    }

    function rollNumber() public view returns(uint256) {
        return rollNo - 1;
    }

}