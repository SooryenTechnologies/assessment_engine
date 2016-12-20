#ASSESSMENT ENGINE :
Assessment Engine is a performance evaluation tool which helps the instructor to analyze performance by creating Quiz/Test and evaluating the student's performance.

#1 Main Features :
	

##Quiz :
	* CRUD of Quiz
	* Quiz List
	* Duplicate whole Quiz with Questions
	* Get the scores information of the Quiz
	* Shuffle Question in the Quiz
	* Shuffle Answer in the Question

##Question :
	* CRUD of Question
	* Question Bank(List of Questions of all Quizzes )
	* List of Questions per Quiz

##Quiz Submission :
	* Manual / Automatically Quiz Submission
	* Grade Quiz
	* Quiz Submission Results
	* Quiz Attempt history of the user


#2 Installation :

For All Mac OS / Linux / Window you need to install `ruby 2.0.0  & Git`.

You can install Ruby from [here](http://railsapps.github.io/installrubyonrails-ubuntu.html).
				 	
Go to console/terminal and Clone the code of `assessment_engine` repository in your system provided above.

Go to assessment_engine folder in the terminal.
	
`$ cd assessment_engine`

Run below command.	

`$ bundle install`

After completion of bundle installation. You can run the application. By below command.
		
`$ rails s`
		 	
You can use any other port in an assessment-engine like below.	

`$ rails s -p 3001`
		 	
You can use any API in your application like this.
			
`https://localhost:30001/api/v1/quizzes`
	
#3 Usage:
	
##1) List of Quiz API :-
	
Controller Name: quizzes_controller/index
EndPoint: http:/root_path/api/v1/quizzes?context_id={context_id}&user_id={user_id}&role={role}
Method: GET
Required/Mandatory Parameters: user_id, context_id, role and client_id

Curl: curl -X GET --header 'Accept: application/json' --header 'X-API-KEY: {your_api_key}' http:/root_path/api/v1/quizzes?context_id={context_id}&user_id={user_id}&role={role}
	
Response of API :
Success :
If their quizzes are present then it will get success response.
Status Code : 200
Response : list of Quiz as JSON.
Ex.
	
```json
{
"quizzes": [
{
"id": 1,
"title": "quiz_1",
"description": "description of quiz",
"context_id": 1,
"resource_link_id": "1",
"points_possible": null,
"shuffle_answers": false,
"show_correct_answers": false,
"time_limit": null,
"allowed_attempts": null,
"quiz_type": "graded_assessment",
"lock_at": null,
"unlock_at": null,
"due_at": null,
"question_count": null,
"published_at": null,
"last_edited_at": "2016-10-27T10:22:25.000Z",
"created_by": 1,
"updated_by": 1,
"hide_results": null,
"one_question_at_a_time": false,
"show_correct_answers_at_date": null,
"show_correct_answers_at_time": null,
"hide_correct_answers_at_date": null,
"hide_correct_answers_at_time": null,
"show_correct_answers_after_last_attempt": null,
"created_at": "2016-10-27T10:22:28.000Z",
"updated_at": "2016-10-27T10:22:28.000Z",
"score_filter": null,
"once_after_each_attempt": null,
"auto_publish": false,
"lock_question_after_answer": false,
"time_limit_check": false,
"show_quiz_response": false,
"allow_multiple_attempt_check": false
},
…
}
```
##Error: 

If you are getting error while using any of the API, then you can recognize error with error code below.	

###Error Code
Error | Message
------------ | -------------
400 | Bad Request
401 | Unauthorized
403 | Forbidden
404 | Entity Not found 
422 | Unprocessable Entity
500 | Internal Server Error

#4 Compatibility:
	
This OpenAPI is created with "Rails  4.1" & "Ruby 2.2.3".
	
#5 License :

GNU AFFERO GENERAL PUBLIC LICENSE, Version 3 [(AGPL-3.0)](http://www.gnu.org/licenses/agpl.html)

#6 Contributors :
		
[Söoryen Technologies](www.sooryen.com) & [Café Learn, Inc](www.cafelearn.com).
