from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.routes.auth import get_current_user
from app.database import get_db
from app.models.models import AdminMessage, User
from app.schemas.schemas import FeedbackCreate

router = APIRouter(prefix="/feedback", tags=["feedback"])


@router.post("", status_code=status.HTTP_201_CREATED)
def submit_feedback(
    payload: FeedbackCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        device_context = None
        if payload.include_device_context:
            device_context = {
                "user_agent": request.headers.get("user-agent"),
                "origin": request.headers.get("origin"),
                "referer": request.headers.get("referer"),
                "client_host": request.client.host if request.client else None,
            }

        priority_label = str(payload.priority)
        subject = f"[{payload.type.upper()} | P{priority_label}] {payload.subject}"

        body_parts = [
            f"Type: {payload.type}",
            f"Priority: {payload.priority}",
            f"Submitted by user_id: {current_user.id}",
        ]

        if payload.contact_email:
            body_parts.append(f"Contact email: {payload.contact_email}")

        body_parts.append("")
        body_parts.append("Details:")
        body_parts.append(payload.details)

        if device_context:
            body_parts.append("")
            body_parts.append("Device Context:")
            for key, value in device_context.items():
                body_parts.append(f"- {key}: {value}")

        message_body = "".join(body_parts)

        feedback_message = AdminMessage(
            subject=subject,
            body=message_body,
            sender_id=current_user.id,
            is_read=False,
        )

        db.add(feedback_message)
        db.commit()
        db.refresh(feedback_message)

        return {
            "message": "Feedback submitted successfully.",
            "id": feedback_message.id,
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit feedback: {str(e)}",
        )
